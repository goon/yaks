import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs

Item {
    id: root
    implicitHeight: mainCol.implicitHeight
    Layout.fillWidth: true

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

    ColumnLayout {
        id: mainCol
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right

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
            Layout.topMargin: Globals.geometry.spacing.sm
            Layout.bottomMargin: Globals.geometry.spacing.sm
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
                spacing: Globals.geometry.spacing.xs

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
                    Layout.topMargin: Globals.geometry.spacing.xs
                    Layout.bottomMargin: Globals.geometry.spacing.xs
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
