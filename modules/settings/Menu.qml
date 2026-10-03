import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs

SettingsPage {
    id: root

    function pushPage(name) {
        StackView.view.pushPage(Qt.resolvedUrl(name), name);
    }

    // The Network row uses the signal-aware device glyph at full strength
    // rather than a Lucide string icon.
    Component {
        id: fullNetworkGlyph

        NetworkGlyph {
            level: 1
            implicitWidth: 22 * Globals.shellScale
            implicitHeight: 22 * Globals.shellScale
        }
    }

    // ── SINGLE SOURCE OF TRUTH ──────────────────────────────────────────

    readonly property var _menuModel: [
        { page: "Style.qml",         title: "Style",         icon: "paintbrush"  },
        { page: "Bar.qml",           title: "Bar",           icon: "panel-top"   },
        { page: "Applications.qml",  title: "Applications",  icon: "layout-grid" },
        { page: "../network/NetworkWifi.qml",      title: "Network",   icon: "wifi",      glyph: true },
        { page: "../network/NetworkBluetooth.qml", title: "Bluetooth", icon: "bluetooth" },
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

    Item {
        Layout.fillWidth: true
        implicitHeight: 0
        BaseIndicator {
            hoverPredicate: root._hoverPredicate
        }
    }

    ColumnLayout {
        id: mainCol
        Layout.fillWidth: true
        // The nav list above and the mixer below are separate blocks, each
        // closed by its own rule, so the blocks touch.
        spacing: 0

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
                leftIconComponent: modelData.glyph ? fullNetworkGlyph : null
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

        BaseSeparator {
            Layout.fillWidth: true
            Layout.topMargin: Globals.geometry.spacing.md
            Layout.bottomMargin: Globals.geometry.spacing.md
        }

        // Notification history lives here as a block of the menu, not as its own
        // module: the bell opens settings, and the cards sit under the mixer.
        ColumnLayout {
            id: notifBlock

            Layout.fillWidth: true
            spacing: 0

            readonly property int notifCount: Notifications.notificationHistory.count
            readonly property bool dndMode: Preferences.notifications.mode === 1

            RowLayout {
                Layout.fillWidth: true
                Layout.leftMargin: Globals.geometry.spacing.sm
                spacing: 0

                BaseIcon {
                    icon: notifBlock.dndMode ? "bell-off" : "bell"
                    size: Globals.typography.icon.md
                    color: notifBlock.dndMode ? Globals.colors.faint : Globals.colors.text
                }

                BaseText {
                    text: "Notifications"
                    font.pixelSize: Globals.typography.size.lg
                    color: Globals.colors.text
                    // Label aligns with nav labels: row inset 8 + icon box 32,
                    // minus icon 18 already laid out = 14.
                    Layout.leftMargin: 14 * Globals.shellScale
                }

                Item {
                    Layout.fillWidth: true
                }

                BaseSwitch {
                    checked: notifBlock.dndMode
                    onToggled: {
                        Preferences.notifications.mode = checked ? 1 : 0
                        Notifications.notificationHistory.clear()
                    }
                }
            }

            ListView {
                id: notifList

                Layout.fillWidth: true
                implicitHeight: contentHeight
                model: Notifications.notificationHistory
                spacing: Globals.geometry.spacing.md
                interactive: false
                visible: notifBlock.notifCount > 0

                delegate: Column {
                    width: ListView.view.width
                    spacing: Globals.geometry.spacing.md

                    NotificationCard {
                        width: parent.width
                        notification: modelData
                        onRightClicked: {
                            if (modelData)
                                modelData.dismiss();
                        }
                    }

                    BaseSeparator {
                        width: parent.width
                        visible: index < notifList.count - 1
                    }
                }
            }

            // ── EMPTY STATE ──────────────────────────────────────────
            // implicitHeight, not Layout.preferredHeight: the block's height is
            // the sum of its children's implicit heights, and a fixed minimum is
            // what keeps the menu from shrinking when the history empties.
            Item {
                Layout.fillWidth: true
                implicitHeight: notifBlock.notifCount === 0 ? 175 * Globals.shellScale : 0
                visible: notifBlock.notifCount === 0
                opacity: visible ? 1 : 0
                Behavior on opacity {
                    BaseMotion {}
                }
                Behavior on height {
                    BaseMotion {}
                }
                clip: true

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: Globals.geometry.spacing.md

                    Item {
                        Layout.alignment: Qt.AlignHCenter
                        width: 32 * Globals.shellScale
                        height: 32 * Globals.shellScale

                        BaseIcon {
                            anchors.centerIn: parent
                            icon: "bell-check"
                            size: 32 * Globals.shellScale
                            color: Globals.colors.muted
                            opacity: notifBlock.dndMode ? 0 : 1
                            rotation: notifBlock.dndMode ? -180 : 0
                            scale: notifBlock.dndMode ? 0.3 : 1
                            Behavior on opacity { BaseMotion {} }
                            Behavior on rotation { BaseMotion {} }
                            Behavior on scale { BaseMotion {} }
                        }

                        BaseIcon {
                            anchors.centerIn: parent
                            icon: "bell-off"
                            size: 32 * Globals.shellScale
                            color: Globals.colors.muted
                            opacity: notifBlock.dndMode ? 1 : 0
                            rotation: notifBlock.dndMode ? 0 : 180
                            scale: notifBlock.dndMode ? 1 : 0.3
                            Behavior on opacity { BaseMotion {} }
                            Behavior on rotation { BaseMotion {} }
                            Behavior on scale { BaseMotion {} }
                        }
                    }

                    Item {
                        Layout.alignment: Qt.AlignHCenter
                        implicitWidth: Math.max(clearLabel.implicitWidth, silenceLabel.implicitWidth)
                        implicitHeight: Math.max(clearLabel.implicitHeight, silenceLabel.implicitHeight)

                        BaseText {
                            id: clearLabel
                            anchors.centerIn: parent
                            text: "CALM"
                            weight: Globals.typography.weight.demi
                            font.letterSpacing: 3
                            color: Globals.colors.faint
                            opacity: notifBlock.dndMode ? 0 : 1
                            scale: notifBlock.dndMode ? 0.85 : 1
                            Behavior on opacity { BaseMotion {} }
                            Behavior on scale { BaseMotion {} }
                        }

                        BaseText {
                            id: silenceLabel
                            anchors.centerIn: parent
                            text: "SILENCE"
                            weight: Globals.typography.weight.demi
                            font.letterSpacing: 3
                            color: Globals.colors.faint
                            opacity: notifBlock.dndMode ? 1 : 0
                            scale: notifBlock.dndMode ? 1 : 0.85
                            Behavior on opacity { BaseMotion {} }
                            Behavior on scale { BaseMotion {} }
                        }
                    }
                }
            }
        }
    }
}
