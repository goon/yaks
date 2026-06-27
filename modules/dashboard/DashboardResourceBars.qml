import QtQuick
import QtQuick.Layouts
import qs

BaseBento {
    id: root
    implicitWidth: 120
    implicitHeight: 320
    hoverEnabled: true



    RowLayout {
        Layout.fillWidth: true
        Layout.fillHeight: true
        spacing: Globals.geometry.spacing.medium

        component ResourceBar: ColumnLayout {
            id: barCol
            property real value: 0.0
            property color color: Globals.colors.primary
            property string icon: ""
            property string label: ""
            property string tempText: ""
            property bool hovered: false

            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 8

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    onEntered: barCol.hovered = true
                    onExited: barCol.hovered = false
                }

                Rectangle {
                    id: trackBg
                    anchors.fill: parent
                    radius: width / 2
                    color: Globals.colors.background
                    border.width: 1
                    border.color: Globals.alpha(Globals.colors.border, 0.1)
                    clip: true

                    Rectangle {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        height: Math.max(0, parent.height - handle.y + 4)
                        radius: parent.radius
                        
                        gradient: Gradient {
                            orientation: Gradient.Vertical
                            GradientStop { position: 0.0; color: Qt.lighter(barCol.color, 1.25) }
                            GradientStop { position: 1.0; color: barCol.color }
                        }
                    }
                }

                Rectangle {
                    id: handle
                    width: parent.width - 8
                    height: width
                    radius: width / 2
                    color: Globals.colors.surface
                    border.width: 1
                    border.color: Globals.alpha(Globals.colors.border, 0.3)
                    
                    x: 4
                    y: (parent.height - height - 8) * (1.0 - barCol.value) + 4

                    Behavior on y {
                        NumberAnimation {
                            duration: 500
                            easing.type: Easing.OutCubic
                        }
                    }

                    BaseText {
                        anchors.centerIn: parent
                        text: barCol.hovered && barCol.tempText !== "" ? barCol.tempText : Math.round(barCol.value * 100)
                        pixelSize: 9
                        weight: Globals.typography.weights.bold
                        color: barCol.color
                    }
                }
            }

            BaseText {
                Layout.alignment: Qt.AlignHCenter
                text: barCol.label
                pixelSize: 9
                weight: Globals.typography.weights.bold
                color: Globals.alpha(Globals.colors.text, 0.4)
            }
        }

        ResourceBar {
            value: Stats.currentCpu
            color: Globals.colors.accent
            icon: "memory"
            label: "CPU"
            tempText: Stats.currentTemp + "°"
        }

        ResourceBar {
            value: Stats.currentRam
            color: Globals.colors.success
            icon: "sd_card"
            label: "RAM"
        }

        ResourceBar {
            value: Stats.currentGpu
            color: Globals.colors.error
            icon: "videogame_asset"
            label: "GPU"
            tempText: Stats.currentGpuTemp + "°"
        }
    }
}
