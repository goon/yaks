import QtQuick
import QtQuick.Layouts
import qs

BaseBlock {
    id: root
    clickable: true
    premiumHover: true

    implicitWidth: 120
    implicitHeight: 320

    padding: Theme.geometry.spacing.large
    paddingHorizontal: padding
    paddingVertical: padding

    RowLayout {
        Layout.fillWidth: true
        Layout.fillHeight: true
        spacing: Theme.geometry.spacing.medium

        // Individual vertical bar helper component
        component ResourceBar: ColumnLayout {
            id: barCol
            property real value: 0.0 // 0.0 to 1.0
            property color color: Theme.colors.primary
            property string icon: ""
            property string label: ""

            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 8

            // 1. Vertical Track Container
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                // Track Background
                Rectangle {
                    id: trackBg
                    anchors.fill: parent
                    radius: width / 2
                    color: Theme.colors.background
                    border.width: 1
                    border.color: Theme.alpha(Theme.colors.border, 0.1)
                    clip: true

                    // Animated fill
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

                // Handle (knob)
                Rectangle {
                    id: handle
                    width: parent.width - 8
                    height: width
                    radius: width / 2
                    color: Theme.colors.surface
                    border.width: 1
                    border.color: Theme.alpha(Theme.colors.border, 0.3)
                    
                    x: 4
                    y: (parent.height - height - 8) * (1.0 - barCol.value) + 4

                    Behavior on y {
                        NumberAnimation {
                            duration: 500
                            easing.type: Easing.OutCubic
                        }
                    }

                    // Value text inside knob (fits 2 digits perfectly)
                    BaseText {
                        anchors.centerIn: parent
                        text: Math.round(barCol.value * 100)
                        pixelSize: 9
                        weight: Theme.typography.weights.bold
                        color: barCol.color
                    }
                }
            }

            // 2. Label (CPU/RAM/GPU) at the bottom
            BaseText {
                Layout.alignment: Qt.AlignHCenter
                text: barCol.label
                pixelSize: 9
                weight: Theme.typography.weights.bold
                color: root.containsMouse ? Theme.alpha(Theme.colors.text, 0.75) : Theme.alpha(Theme.colors.text, 0.4)

                Behavior on color {
                    ColorAnimation { duration: 150 }
                }
            }
        }

        ResourceBar {
            value: Stats.currentCpu
            color: Theme.colors.accent
            icon: "memory"
            label: "CPU"
        }

        ResourceBar {
            value: Stats.currentRam
            color: Theme.colors.success
            icon: "sd_card"
            label: "RAM"
        }

        ResourceBar {
            value: Stats.currentGpu
            color: Theme.colors.error
            icon: "videogame_asset"
            label: "GPU"
        }
    }
}
