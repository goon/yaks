import QtQuick
import Quickshell
import Quickshell.Wayland
import qs

/**
 * Wallpaper freeze
 *
 * Screenshots the whole desktop, applies the new wallpaper behind that frozen
 * image, then erases the screenshot with a shader so the new wallpaper is
 * revealed underneath. Every user wallpaper change goes through here; the point
 * is that the bar, an open popout and the wallpaper itself all land at once,
 * which an in-process crossfade cannot do — it only ever has the one item to
 * animate.
 *
 * The mechanism is shibui-dots' shader-transition, retargeted in-process:
 * upstream launches a second quickshell to run arbitrary theme scripts, so its
 * window is always-on and it ends in Qt.quit(). Here the shell *is* the process,
 * so the windows hide between transitions and `done` unwinds instead of quitting.
 *
 * The phase machine is a plain string, not an enum or a set of booleans: the
 * transitions are strictly sequential, each one entered exactly once, and a
 * string makes an illegal jump a visible no-op rather than a state to reason
 * about.
 *
 * The freeze frame is a Quickshell `ScreencopyView`, not a grim screenshot: the
 * compositor hands the buffer straight to the item and the ShaderEffect samples
 * it, so there is no fork+exec, no PNG on disk and no file to re-decode.
 *
 * Phase: waitForOSDHide → takingScreenshots → overlaySettle → runningTheme
 *      → runningTransition → done
 */
Scope {
    id: root

    property string phase: "done"
    readonly property int totalScreens: Quickshell.screens.length
    property int screensReadyCount: 0
    property int transitionsFinishedCount: 0

    // The wallpaper a wipe is replacing. Held by the root so every screen's
    // window reads the same one.
    property string pendingPath: ""

    readonly property int transitionMs: Math.max(100, Math.round(Preferences.wallpaper.transitionDuration))

    // One settle timer per pause, all named for what they are waiting on rather
    // than reused, because each phase needs a different duration.
    readonly property int _osdHideMs: 150
    // One composited frame is all the opaque overlay needs before the theme
    // swaps underneath it; the phase name is kept for the log.
    readonly property int _overlaySettleMs: 80
    // Backstop only: if Theme never fires `applied` the freeze must still end.
    readonly property int _themeTimeoutMs: 2000

    // ── COORDINATION ───────────────────────────────────────────────────
    // One window per screen, all in one process, so the phases are shared state
    // rather than cross-process messages — but the broadcasts are still the
    // only way in: a window cannot join a phase halfway.
    signal broadcastCapture()
    signal broadcastStartTransition()
    signal broadcastFinish()

    Connections {
        target: Wallpaper
        function onTransitionRequested(path) {
            root.start(path);
        }
    }

    Connections {
        target: Theme
        function onApplied() {
            if (root.phase === "runningTheme") root.beginPhase("runningTransition");
        }
    }

    function start(path) {
        if (root.phase !== "done" || !path) return;
        root.pendingPath = path;
        root.beginPhase("waitForOSDHide");
    }

    function beginPhase(next) {
        root.phase = next;
        console.log("[Transition] ->", next);

        switch (next) {
            case "waitForOSDHide":
                // The bar has to be gone *before* the frame is captured, and the
                // compositor needs a frame or two to actually stop drawing it. A
                // bar baked into the freeze would reappear after the wipe as a
                // pop rather than fading with the rest of the desktop.
                Modules.osdSuppressed = true;
                osdHideTimer.restart();
                break;

            case "takingScreenshots":
                // Every screen maps its window, asks the compositor for one frame
                // and polls for it. There is no process to fail to spawn and no
                // file to decode, so this is the whole capture step — it just has
                // to wait for the compositor to answer.
                root.screensReadyCount = 0;
                root.broadcastCapture();
                break;

            case "overlaySettle":
                loadSettleTimer.restart();
                break;

            case "runningTheme":
                // The desktop is already frozen on screen, so this is the one
                // moment a wallpaper can change without the user seeing it
                // happen. Apply the palette immediately (skipping Theme's
                // debounce) and wait for Theme.applied — not a fixed timer — so
                // the wipe starts the instant the theme is actually done.
                Wallpaper.applyNow(root.pendingPath);
                Theme.requestApply("wallpaper", true);
                themeTimeoutTimer.restart();
                break;

            case "runningTransition":
                themeTimeoutTimer.stop();
                root.transitionsFinishedCount = 0;
                // Commit the deferred wallpaper source swap. The overlay is fully
                // opaque at progress=0, so the swap is invisible; otherwise the
                // wallpaper would flash ~500 ms before the wipe reveals it.
                Wallpaper.commitPending();
                root.broadcastStartTransition();
                break;

            case "done":
                themeTimeoutTimer.stop();
                root.broadcastFinish();
                Modules.osdSuppressed = false;
                root.pendingPath = "";
                // The freeze is over; release the deferred-swap guard so the next
                // unanimated apply reaches WallpaperBackground directly. Cleared
                // before drainQueued so its applyNow is not itself deferred.
                Wallpaper._transitionPending = false;
                root.drainQueued();
                break;
        }
    }

    // A request that landed mid-flight cannot start a second freeze — the screen
    // is already showing a wipe. Apply it plain instead; two freezes back to back
    // read worse than a wallpaper that simply cuts.
    function drainQueued() {
        if (Wallpaper._queuedPath === "") return;
        var queued = Wallpaper._queuedPath;
        Wallpaper._queuedPath = "";
        Wallpaper.applyNow(queued);
    }

    function reportScreenReady() {
        if (root.phase !== "takingScreenshots") return;
        root.screensReadyCount++;
        if (root.screensReadyCount >= root.totalScreens) beginPhase("overlaySettle");
    }

    function reportTransitionFinished() {
        if (root.phase !== "runningTransition") return;
        root.transitionsFinishedCount++;
        if (root.transitionsFinishedCount >= root.totalScreens) beginPhase("done");
    }

    // ── TIMERS ─────────────────────────────────────────────────────────
    Timer {
        id: osdHideTimer
        interval: root._osdHideMs
        onTriggered: root.beginPhase("takingScreenshots")
    }

    Timer {
        id: loadSettleTimer
        interval: root._overlaySettleMs
        onTriggered: root.beginPhase("runningTheme")
    }

    Timer {
        id: themeTimeoutTimer
        interval: root._themeTimeoutMs
        onTriggered: {
            if (root.phase === "runningTheme") root.beginPhase("runningTransition");
        }
    }

    // ── WINDOWS ─────────────────────────────────────────────────────────
    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: transitionWindow

            property var modelData
            screen: modelData

            WlrLayershell.namespace: "yaks:transition"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
            exclusionMode: ExclusionMode.Ignore

            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }

            color: "transparent"
            // Hidden between transitions. Upstream keeps this window up for the
            // life of its throwaway process; yaks has to survive the wipe, and a
            // permanently-live full-screen Overlay window would sit over the
            // desktop swallowing input.
            visible: false

            Connections {
                target: root

                function onBroadcastCapture() {
                    // Order matters. progress stays 1.0 (transparent) until a frame
                    // actually lands, so this window contributes zero alpha to the
                    // very output it is capturing — a mapped-but-transparent layer
                    // is harmless in Hyprland's screencopy. The window has to be
                    // visible before captureFrame() though: the ScreencopyView
                    // needs a scene graph to receive the buffer into.
                    transitionAnim.stop();
                    shader.progress = 1.0;
                    transitionWindow.visible = true;
                    frozenLoader.active = true;
                    capTimer.tries = 0;
                    capTimer.restart();
                    if (frozenLoader.item) frozenLoader.item.captureFrame();
                }

                function onBroadcastStartTransition() {
                    transitionAnim.restart();
                }

                function onBroadcastFinish() {
                    capTimer.stop();
                    transitionWindow.visible = false;
                    // hasContent is sticky — it means "a buffer arrived since
                    // construction", so a surviving view would report ready on the
                    // next transition against the *previous* freeze. Destroying it
                    // is the reset; transitions are rare enough for this to be free.
                    frozenLoader.active = false;
                }
            }

            Loader {
                id: frozenLoader
                active: false
                anchors.fill: parent

                sourceComponent: Component {
                    ScreencopyView {
                        anchors.fill: parent
                        captureSource: transitionWindow.modelData
                        live: false
                        paintCursor: false
                    }
                }
            }

            ShaderEffectSource {
                id: frozenSource
                sourceItem: frozenLoader.item
                // Hidden only once the buffer has landed, which is exactly when
                // capTimer stops. Leaving the sourceItem visible would let it
                // draw the same frozen texture the shader samples *directly*:
                // the wipe then erases the shader's copy and uncovers an
                // identical one, so the transition reads as an instant cut.
                // Not hidden while capturing, because whether a hidden
                // ScreencopyView still receives buffers is untested — which is
                // also why capTimer.restart() precedes captureFrame().
                hideSource: !capTimer.running
            }

            // The compositor answering is a round trip with no callback that
            // reliably distinguishes "not yet" from "never" — hasContentChanged
            // can fire before the first poll, so poll instead, and cap it. Giving
            // up leaves progress at 1.0, i.e. a transparent overlay, so the
            // wallpaper simply cuts. Proceeding is recoverable; hanging is not.
            Timer {
                id: capTimer
                interval: 25
                repeat: true
                running: false

                property int tries: 0

                onTriggered: {
                    const view = frozenLoader.item;
                    if (!view) return;
                    if (view.hasContent) {
                        running = false;
                        shader.progress = 0.0;
                        root.reportScreenReady();
                    } else if (tries > 120) {
                        running = false;
                        root.reportScreenReady();
                    } else {
                        tries += 1;
                        view.captureFrame();
                    }
                }
            }

            ShaderEffect {
                id: shader
                anchors.fill: parent

                // Declaration order matches the ubuf block in wipe.frag
                // (qt_Matrix, qt_Opacity, progress, seed, …) — Qt rejects the
                // shader outright if these two get out of step. `seed` is unused
                // by this fragment — it is declared only because the ubuf block
                // requires it, and removing it would be a load failure.
                //
                // progress defaults to 1.0, not 0.0: 0.0 is fully opaque, and this
                // window is now mapped before the frame arrives, so an opaque
                // default would flash black. Only the captured frame makes it
                // opaque, which is the point.
                property real progress: 1.0
                property real seed: 0.5
                // wipe.frag declares sourceImage as a raw sampler2D, so the only
                // thing binding = 1 needs is a texture — a ShaderEffectSource
                // qualifies. That is why the freeze needs no PNG round trip.
                property ShaderEffectSource sourceImage: frozenSource

                fragmentShader: Qt.resolvedUrl("../../assets/shaders/wipe.frag.qsb")
            }

            NumberAnimation {
                id: transitionAnim
                target: shader
                property: "progress"
                from: 0.0
                to: 1.0
                duration: root.transitionMs
                easing.type: Easing.InOutQuad

                onStopped: root.reportTransitionFinished()
            }
        }
    }
}