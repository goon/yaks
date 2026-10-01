import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell.Widgets
import qs

SettingsPage {
    id: root

    function pushPage(name) {
        StackView.view.pushPage(Qt.resolvedUrl(name), name);
    }

    // ── SINGLE SOURCE OF TRUTH ──────────────────────────────────────────

    readonly property var _menuModel: [
        { page: "Style.qml",         title: "Style",         icon: "paintbrush"  },
        { page: "Bar.qml",           title: "Bar",           icon: "panel-top"   },
        { page: "Applications.qml",  title: "Applications",  icon: "layout-grid" },
    ]

    readonly property Item activeHover: {
        for (var i = 0; i < menuRepeater.count; i++) {
            var item = menuRepeater.itemAt(i);
            if (item && item.hovered) return item;
        }
        return null;
    }

    function _hoverPredicate() {
        // A hovered item always wins, so the pointer can take over from the
        // keyboard immediately; the keyboard highlight only shows when nothing
        // is hovered.
        if (mixerItem.hoveredSlider) return mixerItem.hoveredSlider;
        if (root.activeHover) return root.activeHover;
        for (var i = 0; i < menuRepeater.count; i++) {
            var navItem = menuRepeater.itemAt(i);
            if (navItem && navItem.navHighlighted) return navItem;
        }
        return null;
    }

    // ── POWER TILES ──────────────────────────────────────────────────────

    readonly property var _powerActions: [
        { key: "logout",   icon: "log-out",  run: function() { Modules.closeAll(); Compositor.quit(); } },
        { key: "suspend",  icon: "moon",     run: function() { Modules.closeAll(); Power.suspend(); } },
        { key: "reboot",   icon: "rotate-cw", run: function() { Modules.closeAll(); Power.reboot(); } },
        { key: "shutdown", icon: "power",    run: function() { Modules.closeAll(); Power.shutdown(); } }
    ]

    property string powerHoveredKey: ""

    component PowerTile: Item {
        id: tile

        required property var modelData

        // Fixed, not innerRadius(): a chip is its own shape and must not turn
        // into a circle when the shell rounding goes round.
        readonly property int size: 32 * Globals.shellScale
        readonly property int corner: 8 * Globals.shellScale

        width: tile.size
        height: tile.size

        readonly property bool lit: root.powerHoveredKey === modelData.key

        Rectangle {
            anchors.fill: parent
            radius: tile.corner
            color: tile.lit ? Globals.colors.raised : Globals.colors.well
            border.width: Globals.geometry.borderWidth.hair
            border.color: tile.lit ? Globals.colors.border : Globals.colors.hair

            Behavior on color { BaseMotion { duration: Globals.motion.hover } }
        }

        // The rising fill needs a clip that carries the tile's own corners. A
        // plain Rectangle clamps its radius to height/2 while the fill is still
        // flat, so its corners poke outside the tile outline on the first beat.
        ClippingRectangle {
            anchors.fill: parent
            anchors.margins: Globals.geometry.borderWidth.hair
            radius: tile.corner - Globals.geometry.borderWidth.hair
            color: "transparent"

            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                height: parent.height * hold.hold
                visible: hold.holding
                gradient: Gradient {
                    orientation: Gradient.Vertical
                    GradientStop { position: 0.0; color: Globals.colors.accentTop }
                    GradientStop { position: 1.0; color: Globals.colors.accentBottom }
                }
            }
        }

        BaseIcon {
            anchors.centerIn: parent
            icon: tile.modelData.icon
            size: Globals.typography.icon.md
            color: hold.holding ? Globals.colors.accentTop
                                : Globals.colors.text

            Behavior on color { BaseMotion { duration: Globals.motion.hover } }
        }

        BaseHold {
            id: hold
            onConfirmed: tile.modelData.run()
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor

            onEntered: root.powerHoveredKey = tile.modelData.key
            // Leaving mid-hold drains instead of confirming, so a pointer that
            // slides off never fires the action.
            onExited: {
                if (root.powerHoveredKey === tile.modelData.key)
                    root.powerHoveredKey = "";
                hold.cancel();
            }

            onPressed: hold.press()
            onReleased: hold.release()
        }
    }

    ColumnLayout {
        id: mainCol
        Layout.fillWidth: true
        // The nav rows above and the mixer below are separate blocks, each
        // closed by its own rule, so the blocks touch.
        spacing: 0

        RowLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignRight
            spacing: Globals.geometry.spacing.sm

            Repeater {
                model: root._powerActions

                delegate: PowerTile {}
            }
        }

        BaseSeparator {
            Layout.fillWidth: true
            Layout.topMargin: Globals.geometry.spacing.md
            Layout.bottomMargin: Globals.geometry.spacing.md
        }

        Repeater {
            id: menuRepeater
            model: root._menuModel

            delegate: BaseListItem {
                required property int index
                required property var modelData

                title: modelData.title
                clickable: true
                bounceTitleOnHover: true
                verticalPadding: 0
                leftIcon: modelData.icon
                // The nav list is one block, closed by the separator below it,
                // so it opts out of the per-row rule every settings row draws.
                showSeparator: false
                onClicked: root.pushPage(modelData.page)
            }
        }

        BaseSeparator {
            Layout.fillWidth: true
            Layout.topMargin: Globals.geometry.spacing.md
            Layout.bottomMargin: Globals.geometry.spacing.md
        }

        Item {
            id: mixerItem

            Layout.fillWidth: true
            implicitHeight: mixerCol.implicitHeight

            property string source: "output"

            readonly property bool inputActive: mixerItem.source === "input"
            readonly property bool activeMuted: mixerItem.inputActive ? Audio.inputMuted : Audio.muted

            readonly property Item hoveredSlider: {
                if (audioSlider.hovered) return audioSlider;
                if (displaySlider.hovered) return displaySlider;
                return null;
            }

            function _setActiveVolume(val) {
                if (mixerItem.inputActive) Audio.setInputVolume(val);
                else Audio.setVolume(val);
            }

            function _toggleActiveMute() {
                if (mixerItem.inputActive) Audio.toggleInputMute();
                else Audio.toggleMute();
            }

            component SourceIcon: Item {
                id: sourceIcon

                property string primaryIcon: ""
                property string secondaryIcon: ""
                property bool secondary: false
                property int size: Globals.typography.icon.md
                property color color: Globals.colors.text
                property bool muted: false

                signal clicked()
                signal rightClicked()

                implicitWidth: size
                implicitHeight: size

                opacity: muted ? 0.6 : 1.0
                Behavior on opacity { BaseMotion { } }

                BaseIcon {
                    anchors.centerIn: parent
                    width: sourceIcon.size
                    height: sourceIcon.size
                    icon: sourceIcon.primaryIcon
                    size: sourceIcon.size
                    color: sourceIcon.color
                    opacity: sourceIcon.secondary ? 0 : 1
                    scale: sourceIcon.secondary ? 0.8 : 1.0
                    Behavior on opacity { BaseMotion { } }
                    Behavior on scale { BaseMotion { } }
                }

                BaseIcon {
                    anchors.centerIn: parent
                    width: sourceIcon.size
                    height: sourceIcon.size
                    icon: sourceIcon.secondaryIcon
                    size: sourceIcon.size
                    color: sourceIcon.color
                    opacity: sourceIcon.secondary ? 1 : 0
                    scale: sourceIcon.secondary ? 1.0 : 0.8
                    Behavior on opacity { BaseMotion { } }
                    Behavior on scale { BaseMotion { } }
                }

                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -Globals.geometry.spacing.xs
                    hoverEnabled: true
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    cursorShape: Qt.PointingHandCursor
                    onClicked: (mouse) => {
                        if (mouse.button === Qt.RightButton)
                            sourceIcon.rightClicked();
                        else
                            sourceIcon.clicked();
                    }
                }
            }

            ColumnLayout {
                id: mixerCol
                anchors.fill: parent
                // The two separators own all the air in this block, so the
                // sliders touch and both get the same step either side. A gap
                // here would only ever land under the top row and push it
                // high against the rule above.
                spacing: 0

                RowLayout {
                    Layout.fillWidth: true
                    Layout.leftMargin: Globals.geometry.spacing.sm
                    spacing: Globals.geometry.spacing.md

                    SourceIcon {
                        Layout.alignment: Qt.AlignVCenter
                        size: Globals.typography.icon.md
                        muted: mixerItem.activeMuted
                        secondary: mixerItem.inputActive
                        primaryIcon: Audio.muted ? "volume-off" : "volume-2"
                        secondaryIcon: Audio.inputMuted ? "mic-off" : "mic"
                        onClicked: mixerItem.source = mixerItem.inputActive ? "output" : "input"
                        onRightClicked: mixerItem._toggleActiveMute()
                    }

                    BaseSlider {
                        id: audioSlider

                        Layout.fillWidth: true
                        stepSize: 0.01
                        muted: mixerItem.activeMuted

                        Binding on value {
                            value: mixerItem.inputActive ? Audio.inputVolume : Audio.volume
                            when: !audioSlider.pressed
                            restoreMode: Binding.RestoreBinding
                        }
                        onValueChangedByUser: mixerItem._setActiveVolume(value)
                        onRightClicked: mixerItem._toggleActiveMute()
                    }
                }

                BaseSeparator {
                    Layout.fillWidth: true
                    Layout.topMargin: Globals.geometry.spacing.md
                    Layout.bottomMargin: Globals.geometry.spacing.md
                }

                BaseSlider {
                    id: displaySlider

                    Layout.fillWidth: true
                    Layout.leftMargin: Globals.geometry.spacing.sm
                    iconSize: Globals.typography.icon.md
                    iconGap: Globals.geometry.spacing.md
                    icon: "sun"
                    stepSize: 0.01

                    Binding on value {
                        value: Display.brightness
                        when: !displaySlider.pressed
                        restoreMode: Binding.RestoreBinding
                    }
                    onValueChangedByUser: Display.setBrightness(value)
                }
            }
        }
    }

    BaseIndicator {
        hoverPredicate: root._hoverPredicate
    }
}
