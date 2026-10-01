import QtQuick
import QtQuick.Layouts
import qs

Item {
    id: root

    Layout.fillWidth: true
    implicitHeight: mainCol.implicitHeight

    // ── ACTIVE SOURCE ───────────────────────────────────────────────────

    property string source: "output"

    readonly property bool inputActive: root.source === "input"
    readonly property bool activeMuted: root.inputActive ? Audio.inputMuted : Audio.muted

    readonly property Item hoveredSlider: {
        if (audioSlider.hovered) return audioSlider;
        if (displaySlider.hovered) return displaySlider;
        return null;
    }

    function _setActiveVolume(val) {
        if (root.inputActive) Audio.setInputVolume(val);
        else Audio.setVolume(val);
    }

    function _toggleActiveMute() {
        if (root.inputActive) Audio.toggleInputMute();
        else Audio.toggleMute();
    }

    // ── SOURCE TOGGLE ICON ──────────────────────────────────────────────

    component SourceIcon: Item {
        id: sourceIcon

        property string primaryIcon: ""
        property string secondaryIcon: ""
        property bool secondary: false
        property int size: Globals.dimensions.iconMedium
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
            anchors.margins: -Globals.geometry.spacing.small
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
        id: mainCol
        anchors.fill: parent
        spacing: Globals.geometry.spacing.small

        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: Globals.geometry.spacing.medium
            spacing: Globals.geometry.spacing.large

            SourceIcon {
                Layout.alignment: Qt.AlignVCenter
                size: Globals.dimensions.iconMedium
                muted: root.activeMuted
                secondary: root.inputActive
                primaryIcon: Audio.muted ? "volume-off" : "volume-2"
                secondaryIcon: Audio.inputMuted ? "mic-off" : "mic"
                onClicked: root.source = root.inputActive ? "output" : "input"
                onRightClicked: root._toggleActiveMute()
            }

            BaseSlider {
                id: audioSlider

                Layout.fillWidth: true
                stepSize: 0.01
                muted: root.activeMuted

                Binding on value {
                    value: root.inputActive ? Audio.inputVolume : Audio.volume
                    when: !audioSlider.pressed
                    restoreMode: Binding.RestoreBinding
                }
                onValueChangedByUser: root._setActiveVolume(value)
                onRightClicked: root._toggleActiveMute()
            }
        }

        BaseSeparator {
            Layout.fillWidth: true
            Layout.topMargin: Globals.geometry.spacing.small
            Layout.bottomMargin: Globals.geometry.spacing.small
        }

        BaseSlider {
            id: displaySlider

            Layout.fillWidth: true
            Layout.leftMargin: Globals.geometry.spacing.medium
            iconSize: Globals.dimensions.iconMedium
            iconGap: Globals.geometry.spacing.large
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
