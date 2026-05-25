import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Mpris
import qs

BaseBlock {
    id: root

    implicitWidth: 300

    borderEnabled: false
    backgroundColor: Theme.alpha(Theme.colors.surface, Theme.blur.surfaceOpacity)
    hoverEnabled: false



    function formatTime(seconds) {
        if (isNaN(seconds) || seconds < 0 || !isFinite(seconds)) return "00:00";
        var m = Math.floor(seconds / 60);
        var s = Math.floor(seconds % 60);
        return (m < 10 ? "0" + m : m) + ":" + (s < 10 ? "0" + s : s);
    }



    ColumnLayout {
        Layout.fillWidth: true
        Layout.fillHeight: true
        spacing: Theme.geometry.spacing.large

        // 1. CIRCULAR ALBUM ART with CAVA Equalizer
        Item {
            id: albumArtWrapper
            Layout.fillWidth: true
            implicitHeight: width  // Always square

            readonly property int visualBarsCount: 96
            readonly property real barWidth: (Math.PI * (albumArtCircle.width + 8) / visualBarsCount) * 0.45

            function interpolateColor(color1, color2, factor) {
                var c1 = Qt.color(color1);
                var c2 = Qt.color(color2);
                return Qt.rgba(
                    c1.r + (c2.r - c1.r) * factor,
                    c1.g + (c2.g - c1.g) * factor,
                    c1.b + (c2.b - c1.b) * factor,
                    c1.a + (c2.a - c1.a) * factor
                );
            }

            // Helper for circle dimensions
            Item {
                id: albumArtCircle
                anchors.centerIn: parent
                width: parent.width - 84
                height: width
            }

            // Radiating Equalizer (CAVA)
            Item {
                anchors.fill: parent
                opacity: Media.playbackState === MprisPlaybackState.Playing ? 1.0 : 0.0

                Behavior on opacity {
                    NumberAnimation {
                        duration: 300
                        easing.type: Easing.InOutQuad
                    }
                }

                Repeater {
                    model: albumArtWrapper.visualBarsCount

                    delegate: Item {
                        id: delegateItem
                        anchors.centerIn: parent
                        
                        property real barVal: {
                            var spec = Cava.spectrum;
                            if (!spec || spec.length < 48) return 0.0;
                            var bandIndex = 0;
                            if (index < 48) {
                                bandIndex = 47 - index;
                            } else {
                                bandIndex = index - 48;
                            }
                            return spec[bandIndex];
                        }
                        
                        width: albumArtWrapper.barWidth
                        height: albumArtCircle.width + 114
                        rotation: (index / albumArtWrapper.visualBarsCount) * 360

                        // Clipped container to keep bottom flat and top rounded
                        Item {
                            anchors.horizontalCenter: parent.horizontalCenter
                            y: parent.height / 2 - (albumArtCircle.width / 2 + 8) - height
                            width: parent.width
                            height: Math.pow(delegateItem.barVal, 0.65) * 48
                            opacity: Math.min(1.0, delegateItem.barVal * 6.0)
                            clip: true

                            Behavior on height {
                                NumberAnimation {
                                    duration: 80
                                    easing.type: Easing.OutCubic
                                }
                            }

                            Behavior on opacity {
                                NumberAnimation {
                                    duration: 80
                                }
                            }

                            Rectangle {
                                anchors.horizontalCenter: parent.horizontalCenter
                                anchors.top: parent.top
                                width: parent.width
                                height: parent.height + 10
                                radius: 0
                                color: {
                                    var factor = index / albumArtWrapper.visualBarsCount;
                                    var symFactor = Math.abs(0.5 - factor) * 2;
                                    return albumArtWrapper.interpolateColor(Theme.colors.secondary, Theme.colors.primary, symFactor);
                                }
                            }
                        }
                    }
                }
            }
            // Rotating Gradient Ring border for Album Art
            Canvas {
                id: ringCanvas
                anchors.centerIn: albumArtCircle
                width: albumArtCircle.width + 10
                height: width

                onPaint: {
                    var ctx = getContext("2d");
                    ctx.clearRect(0, 0, width, height);

                    var lineWidth = 1.5;
                    var cx = width / 2;
                    var cy = height / 2;
                    var r = (width - lineWidth) / 2;

                    ctx.beginPath();
                    ctx.arc(cx, cy, r, 0, 2 * Math.PI);

                    var grad = ctx.createLinearGradient(0, 0, width, height);
                    grad.addColorStop(0.0, Theme.colors.primary);
                    grad.addColorStop(1.0, Theme.colors.secondary);

                    ctx.strokeStyle = grad;
                    ctx.lineWidth = lineWidth;
                    ctx.stroke();
                }

                onWidthChanged: requestPaint()
                onHeightChanged: requestPaint()

                RotationAnimation {
                    target: ringCanvas
                    property: "rotation"
                    from: 0
                    to: 360
                    duration: 12000 // 12 seconds per full rotation for a smooth, premium feel
                    loops: Animation.Infinite
                    running: true
                }
            }

            // Mask for circular crop
            Rectangle {
                id: albumArtMask
                width: albumArtCircle.width
                height: albumArtCircle.height
                anchors.centerIn: parent
                radius: width / 2
                color: Theme.colors.text
                visible: false
                layer.enabled: true
                layer.smooth: true
                layer.samples: 8
            }

            // Outer masked layer
            Item {
                anchors.fill: albumArtCircle
                layer.enabled: true
                layer.smooth: true
                layer.samples: 8
                layer.effect: MultiEffect {
                    maskEnabled: true
                    maskSource: albumArtMask
                    maskThresholdMin: 0.5
                    maskSpreadAtMin: 1.0
                }

                // Inner layer: images + blur background
                Item {
                    id: albumArtContainer
                    anchors.fill: parent

                    property bool useArt2: false

                    Connections {
                        target: Media
                        function onAlbumArtUrlChanged() {
                            if (albumArtContainer.useArt2) {
                                if (art1.source !== Media.albumArtUrl) art1.source = Media.albumArtUrl;
                            } else {
                                if (art2.source !== Media.albumArtUrl) art2.source = Media.albumArtUrl;
                            }
                        }
                    }

                    // Beating scale shared by both images
                    property real breathScale: 1.0
                    SequentialAnimation {
                        loops: Animation.Infinite
                        running: true
                        paused: Media.playbackState !== MprisPlaybackState.Playing

                        NumberAnimation { target: albumArtContainer; property: "breathScale"; to: 1.04; duration: 1200; easing.type: Easing.InOutSine }
                        NumberAnimation { target: albumArtContainer; property: "breathScale"; to: 1.0;  duration: 1200; easing.type: Easing.InOutSine }
                    }

                    Image {
                        id: art1
                        anchors.centerIn: parent
                        width: parent.width
                        height: parent.height
                        source: Media.albumArtUrl
                        fillMode: Image.PreserveAspectCrop
                        opacity: !albumArtContainer.useArt2 ? 1.0 : 0.0
                        visible: opacity > 0.01

                        Behavior on opacity { BaseAnimation { speed: "slow" } }

                        scale: albumArtContainer.breathScale

                        onStatusChanged: {
                            if (status === Image.Ready && albumArtContainer.useArt2)
                                albumArtContainer.useArt2 = false;
                        }
                    }

                    Image {
                        id: art2
                        anchors.centerIn: parent
                        width: parent.width
                        height: parent.height
                        source: ""
                        fillMode: Image.PreserveAspectCrop
                        opacity: albumArtContainer.useArt2 ? 1.0 : 0.0
                        visible: opacity > 0.01

                        Behavior on opacity { BaseAnimation { speed: "slow" } }

                        scale: albumArtContainer.breathScale

                        onStatusChanged: {
                            if (status === Image.Ready && !albumArtContainer.useArt2)
                                albumArtContainer.useArt2 = true;
                        }
                    }
                }

                // Vignette overlay inside the circle
                Canvas {
                    id: vignetteCanvas
                    anchors.fill: parent
                    onWidthChanged: requestPaint()
                    onHeightChanged: requestPaint()
                    onPaint: {
                        var ctx = getContext("2d");
                        ctx.clearRect(0, 0, width, height);
                        var cx = width / 2;
                        var cy = height / 2;
                        var r = width / 2;
                        var gradient = ctx.createRadialGradient(cx, cy, r * 0.75, cx, cy, r);
                        gradient.addColorStop(0.0, "transparent");
                        gradient.addColorStop(1.0, "rgba(0, 0, 0, 0.40)");
                        ctx.fillStyle = gradient;
                        ctx.beginPath();
                        ctx.arc(cx, cy, r, 0, 2 * Math.PI);
                        ctx.fill();
                    }
                }

                // Inset border overlay for clean circular look
                Rectangle {
                    anchors.fill: parent
                    radius: width / 2
                    color: "transparent"
                    border.color: Theme.alpha(Theme.colors.text, 0.15)
                    border.width: 1.5
                }
            }


            // Fallback when no art
            Rectangle {
                anchors.fill: albumArtCircle
                radius: width / 2
                color: Theme.alpha(Theme.colors.background, 0.6)
                visible: !Media.activePlayer || Media.albumArtUrl === ""

                BaseIcon {
                    anchors.centerIn: parent
                    icon: "music_note"
                    size: Theme.dimensions.iconExtraLarge
                    color: Theme.alpha(Theme.colors.primary, 0.4)
                }
            }
        }

        // 2. TRACK TITLE + ARTIST
        ColumnLayout {
            Layout.fillWidth: true
            spacing: Theme.geometry.spacing.small



            BaseText {
                Layout.fillWidth: true
                text: Media.activePlayer ? Media.trackTitle : "No Media Playing"
                pixelSize: Theme.typography.size.large
                weight: Theme.typography.weights.bold
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
                color: Theme.colors.text
            }

            BaseText {
                Layout.fillWidth: true
                text: Media.activePlayer ? Media.trackArtist : "Standby"
                pixelSize: Theme.typography.size.medium
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
                color: Theme.colors.muted
            }
        }

        // 3. PROGRESS BAR
        ColumnLayout {
            Layout.fillWidth: true
            spacing: Theme.geometry.spacing.small

            Slider {
                id: progressSlider

                property real wavePhase: 0
                property real waveAmplitude: 4
                property real waveFrequency: 0.15

                Layout.fillWidth: true
                Layout.preferredHeight: 32
                
                Connections {
                    target: Media
                    function onProgressRatioChanged() {
                        if (!progressSlider.pressed) {
                            progressSlider.value = Media.progressRatio;
                        }
                    }
                }
                
                enabled: Media.activePlayer !== null
                
                onMoved: {
                    if (Media.trackLength > 0) {
                        Media.seek(value * Media.trackLength);
                    }
                }

                onPressedChanged: {
                    if (!pressed) {
                        if (Media.trackLength > 0) {
                            Media.seek(value * Media.trackLength);
                        }
                    }
                }

                BaseAnimation {
                    from: 0
                    to: -Math.PI * 2
                    speed: "slow"
                    loops: Animation.Infinite
                    running: Media.playbackState === MprisPlaybackState.Playing
                    target: progressSlider
                    property: "wavePhase"
                    easing.type: Easing.Linear
                }

                background: Item {
                    x: progressSlider.leftPadding
                    y: progressSlider.topPadding + (progressSlider.availableHeight / 2) - (height / 2)
                    width: progressSlider.availableWidth
                    height: 24

                    Canvas {
                        id: waveCanvas

                        property real progress: progressSlider.visualPosition
                        Behavior on progress { BaseAnimation.Spring { profile: "snappy" } }

                        property color activeColor: Theme.colors.text
                        property color inactiveColor: Theme.alpha(Theme.colors.text, 0.08)
                        property real phase: progressSlider.wavePhase

                        anchors.fill: parent
                        onProgressChanged: requestPaint()
                        onPhaseChanged: requestPaint()
                        onPaint: {
                            var ctx = getContext("2d");
                            ctx.clearRect(0, 0, width, height);
                            var midY = height / 2;
                            var amplitude = progressSlider.waveAmplitude;
                            var frequency = progressSlider.waveFrequency;
                            var progressX = progress * (width - 2);
                            var lineWidth = 4;
                            ctx.beginPath();
                            ctx.strokeStyle = inactiveColor;
                            ctx.lineWidth = lineWidth;
                            ctx.lineCap = "round";
                            ctx.moveTo(progressX, midY);
                            ctx.lineTo(width, midY);
                            ctx.stroke();
                            ctx.beginPath();
                            if (progressX > 0) {
                                var gradient = ctx.createLinearGradient(0, 0, progressX, 0);
                                gradient.addColorStop(0, Theme.colors.primary);
                                gradient.addColorStop(1, Theme.colors.secondary);
                                ctx.strokeStyle = gradient;
                            } else {
                                ctx.strokeStyle = activeColor;
                            }
                            ctx.lineWidth = lineWidth;
                            ctx.lineCap = "round";
                            if (progressX > 0) {
                                ctx.moveTo(0, midY + Math.sin(phase) * amplitude);
                                for (var x = 1; x <= progressX; x++) {
                                    var y = midY + Math.sin(x * frequency + phase) * amplitude;
                                    ctx.lineTo(x, y);
                                }
                                ctx.stroke();
                            }
                        }
                    }

                    Rectangle {
                        x: 0
                        y: parent.height / 2 - 10
                        width: 4
                        height: Theme.dimensions.iconMedium
                        radius: Math.max(2, Theme.geometry.radius * 0.5)
                        color: Theme.colors.text
                    }
                }

                handle: Rectangle {
                    z: 1
                    x: progressSlider.leftPadding + progressSlider.visualPosition * (progressSlider.availableWidth - width)
                    Behavior on x { BaseAnimation.Spring { profile: "snappy" } }
                    
                    y: progressSlider.topPadding + progressSlider.availableHeight / 2 - height / 2
                    width: 4
                    height: Theme.dimensions.iconMedium
                    radius: Math.max(2, Theme.geometry.radius * 0.5)
                    color: Theme.colors.text
                }
            }

            RowLayout {
                Layout.fillWidth: true

                BaseText {
                    text: root.formatTime(Media.currentPosition)
                    pixelSize: Theme.typography.size.small
                    color: Theme.colors.muted
                }

                Item { Layout.fillWidth: true }

                BaseText {
                    text: root.formatTime(Media.trackLength / 1e+06)
                    pixelSize: Theme.typography.size.small
                    color: Theme.colors.muted
                }
            }
        }

        // 4. MEDIA CONTROLS
        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 24

            BaseButton {
                id: prevBtn
                size: Theme.dimensions.iconBase
                hoverGradient: true
                icon: "skip_previous"
                enabled: Media.canGoPrevious
                onClicked: {
                    prevAnim.restart()
                    Media.previous()
                }

                NumberAnimation {
                    id: prevAnim
                    target: prevBtn
                    property: "iconRotation"
                    from: 0
                    to: -360
                    duration: 500
                    easing.type: Easing.OutBack
                }
            }

            BaseButton {
                size: Theme.dimensions.iconBase
                hoverGradient: true
                icon: Media.playbackState === MprisPlaybackState.Playing ? "pause" : "play_arrow"
                enabled: Media.activePlayer !== null
                onClicked: Media.togglePlayPause()
                
                iconRotation: Media.playbackState === MprisPlaybackState.Playing ? 180 : 0
                Behavior on iconRotation { BaseAnimation { speed: "fast"; easing.type: Easing.InOutBack } }
            }

            BaseButton {
                id: nextBtn
                size: Theme.dimensions.iconBase
                hoverGradient: true
                icon: "skip_next"
                enabled: Media.canGoNext
                onClicked: {
                    nextAnim.restart()
                    Media.next()
                }

                NumberAnimation {
                    id: nextAnim
                    target: nextBtn
                    property: "iconRotation"
                    from: 0
                    to: 360
                    duration: 500
                    easing.type: Easing.OutBack
                }
            }
        }
    }
}