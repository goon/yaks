import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs
import qs.services

Item {
    id: root

    Layout.fillWidth: true
    implicitHeight: mainLayout.implicitHeight
    implicitWidth: mainLayout.implicitWidth

    // State for the expandable layout
    property string expandedSide: "" // "", "output", "input"

    ColumnLayout {
        id: mainLayout
        anchors.fill: parent
        spacing: Theme.geometry.spacing.medium

        // --- ROW 0: QUICK ACTION BUTTONS (Smooth Animated Header) ---
        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: 64

            // Output Button
            BaseButton {
                id: outBtn
                x: 0
                width: expandedSide === "output" ? parent.width : (expandedSide === "input" ? 0 : (parent.width - Theme.geometry.spacing.medium) / 2)
                height: parent.height
                visible: opacity > 0
                opacity: expandedSide === "input" ? 0 : 1
                clip: true

                Behavior on width { BaseAnimation { speed: "fast" } }
                Behavior on opacity { BaseAnimation { speed: "fast" } }

                customRadius: Theme.geometry.radius * 1.5
                gradient: true
                selected: !Volume.muted
                normalColor: expandedSide === "output" ? Theme.alpha(Theme.colors.surface, 0.6) : Theme.alpha(Theme.colors.surface, Theme.opacity.surface)
                onClicked: expandedSide = (expandedSide === "output") ? "" : "output"

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: Theme.geometry.spacing.medium
                    anchors.rightMargin: Theme.geometry.spacing.large
                    spacing: Theme.geometry.spacing.medium

                    BaseButton {
            buttonMode: "action"
                        icon: Volume.volumeIcon
                        active: !Volume.muted
                        inactiveColor: Theme.colors.text
                        inactiveBackgroundColor: Theme.colors.text
                        inactiveBackgroundOpacity: 0.1
                        onClicked: Volume.toggleMute()
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0
                        BaseText {
                            text: "Output"
                            pixelSize: Theme.typography.size.base
                            weight: Theme.typography.weights.medium
                            color: Theme.colors.text
                        }
                        BaseText {
                            text: Volume.getNodeName(Volume.audioSink)
                            pixelSize: Theme.typography.size.small
                            color: Theme.colors.muted
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }
                    }

                    BaseIcon {
                        icon: "expand_more"
                        size: Theme.dimensions.iconMedium
                        color: Theme.alpha(Theme.colors.text, 0.3)
                        Layout.alignment: Qt.AlignVCenter
                        rotation: expandedSide === "output" ? 180 : 0
                        Behavior on rotation { BaseAnimation { speed: "fast" } }
                    }
                }
            }

            // Input Button
            BaseButton {
                id: inBtn
                x: expandedSide === "input" ? 0 : (expandedSide === "output" ? parent.width : (parent.width + Theme.geometry.spacing.medium) / 2)
                width: expandedSide === "input" ? parent.width : (expandedSide === "output" ? 0 : (parent.width - Theme.geometry.spacing.medium) / 2)
                height: parent.height
                visible: opacity > 0
                opacity: expandedSide === "output" ? 0 : 1
                clip: true

                Behavior on x { BaseAnimation { speed: "fast" } }
                Behavior on width { BaseAnimation { speed: "fast" } }
                Behavior on opacity { BaseAnimation { speed: "fast" } }

                customRadius: Theme.geometry.radius * 1.5
                gradient: true
                selected: !Volume.inputMuted
                normalColor: expandedSide === "input" ? Theme.alpha(Theme.colors.surface, 0.6) : Theme.alpha(Theme.colors.surface, Theme.opacity.surface)
                onClicked: expandedSide = (expandedSide === "input") ? "" : "input"

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: Theme.geometry.spacing.large
                    anchors.rightMargin: Theme.geometry.spacing.medium
                    spacing: Theme.geometry.spacing.medium

                    BaseIcon {
                        icon: "expand_more"
                        size: Theme.dimensions.iconMedium
                        color: Theme.alpha(Theme.colors.text, 0.3)
                        Layout.alignment: Qt.AlignVCenter
                        rotation: expandedSide === "input" ? 180 : 0
                        Behavior on rotation { BaseAnimation { speed: "fast" } }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0
                        BaseText {
                            text: "Input"
                            pixelSize: Theme.typography.size.base
                            weight: Theme.typography.weights.medium
                            color: Theme.colors.text
                            horizontalAlignment: Text.AlignRight
                            Layout.fillWidth: true
                        }
                        BaseText {
                            text: Volume.getNodeName(Volume.audioSource)
                            pixelSize: Theme.typography.size.small
                            color: Theme.colors.muted
                            elide: Text.ElideLeft
                            horizontalAlignment: Text.AlignRight
                            Layout.fillWidth: true
                        }
                    }

                    BaseButton {
            buttonMode: "action"
                        icon: Volume.inputMuted ? "mic_off" : "mic"
                        active: !Volume.inputMuted
                        inactiveColor: Theme.colors.text
                        inactiveBackgroundColor: Theme.colors.text
                        inactiveBackgroundOpacity: 0.1
                        onClicked: Volume.toggleInputMute()
                    }
                }
            }
        }

        // --- EXPANDED OUTPUT LIST ---
        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: expandedSide === "output" ? outputListCol.implicitHeight : 0
            opacity: expandedSide === "output" ? 1 : 0
            visible: opacity > 0
            clip: true

            Behavior on Layout.preferredHeight { BaseAnimation { speed: "fast" } }
            Behavior on opacity { BaseAnimation { speed: "fast" } }

            ColumnLayout {
                id: outputListCol
                width: parent.width
                spacing: Theme.geometry.spacing.small

                Repeater {
                    model: Volume.sinks
                    delegate: BaseButton {
                        id: sinkButton
                        Layout.fillWidth: true
                        Layout.preferredHeight: 50
                        gradient: true
                        selected: (Volume.audioSink && Volume.audioSink.id === modelData.id) || containsMouse
                        normalColor: Theme.alpha(Theme.colors.surface, Theme.opacity.surface)
                        hoverColor: Theme.colors.background
                        contentAlignment: Qt.AlignLeft
                        paddingHorizontal: Theme.geometry.spacing.dynamicPadding

                        onClicked: {
                            Volume.selectSink(modelData.id);
                            root.expandedSide = "";
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: parent.paddingHorizontal
                            anchors.rightMargin: parent.paddingHorizontal
                            spacing: Theme.geometry.spacing.medium

                            BaseIcon {
                                readonly property bool isActive: Volume.audioSink && Volume.audioSink.id === modelData.id
                                icon: isActive ? "task_alt" : "circle"
                                fill: isActive
                                color: sinkButton.iconColor
                                size: Theme.dimensions.iconBase
                                Layout.alignment: Qt.AlignVCenter
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2
                                Layout.alignment: Qt.AlignVCenter

                                BaseText {
                                    text: Volume.getNodeName(modelData)
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                    color: sinkButton.textColor
                                    weight: sinkButton.weight
                                }
                            }
                        }
                    }
                }
            }
        }

        // --- EXPANDED INPUT LIST ---
        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: expandedSide === "input" ? inputListCol.implicitHeight : 0
            opacity: expandedSide === "input" ? 1 : 0
            visible: opacity > 0
            clip: true

            Behavior on Layout.preferredHeight { BaseAnimation { speed: "fast" } }
            Behavior on opacity { BaseAnimation { speed: "fast" } }

            ColumnLayout {
                id: inputListCol
                width: parent.width
                spacing: Theme.geometry.spacing.small

                Repeater {
                    model: Volume.sources
                    delegate: BaseButton {
                        id: sourceButton
                        Layout.fillWidth: true
                        Layout.preferredHeight: 50
                        gradient: true
                        selected: (Volume.audioSource && Volume.audioSource.id === modelData.id) || containsMouse
                        normalColor: Theme.alpha(Theme.colors.surface, Theme.opacity.surface)
                        hoverColor: Theme.colors.background
                        contentAlignment: Qt.AlignLeft
                        paddingHorizontal: Theme.geometry.spacing.dynamicPadding

                        onClicked: {
                            Volume.selectSource(modelData.id);
                            root.expandedSide = "";
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: parent.paddingHorizontal
                            anchors.rightMargin: parent.paddingHorizontal
                            spacing: Theme.geometry.spacing.medium

                            BaseIcon {
                                readonly property bool isActive: Volume.audioSource && Volume.audioSource.id === modelData.id
                                icon: isActive ? "task_alt" : "circle"
                                fill: isActive
                                color: sourceButton.iconColor
                                size: Theme.dimensions.iconBase
                                Layout.alignment: Qt.AlignVCenter
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2
                                Layout.alignment: Qt.AlignVCenter

                                BaseText {
                                    text: Volume.getNodeName(modelData)
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                    color: sourceButton.textColor
                                    weight: sourceButton.weight
                                }
                            }
                        }
                    }
                }
            }
        }

        // --- SLIDERS ---
        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: expandedSide === "" ? slidersBlock.implicitHeight : 0
            opacity: expandedSide === "" ? 1 : 0
            visible: opacity > 0
            clip: true
            
            Behavior on Layout.preferredHeight { BaseAnimation { speed: "fast" } }
            Behavior on opacity { BaseAnimation { speed: "fast" } }

            BaseBlock {
                id: slidersBlock
                width: parent.width
                paddingVertical: Theme.geometry.spacing.large

                ColumnLayout {
                    anchors.fill: parent
                    spacing: Theme.geometry.spacing.large

                // Master Volume
                BaseSlider {
                    id: outputSlider
                    Layout.fillWidth: true
                    trackHeight: 38
                    icon: Volume.volumeIcon
                    suffix: Math.round(Volume.volume * 100)
                    iconColor: Theme.colors.text
                    suffixColor: Theme.colors.text
                    iconSize: Theme.dimensions.iconMedium
                    from: 0
                    to: 1
                    stepSize: 0.01
                    onValueChangedByUser: Volume.setVolume(value)
                    onIconClicked: Volume.toggleMute()

                    Binding on value {
                        value: Volume.volume
                        when: !outputSlider.pressed
                        restoreMode: Binding.RestoreBinding
                    }
                }

                BaseSeparator { Layout.fillWidth: true; opacity: 0.1 }

                // Mic Volume
                BaseSlider {
                    id: inputSlider
                    Layout.fillWidth: true
                    trackHeight: 38
                    icon: Volume.inputMuted ? "mic_off" : "mic"
                    suffix: Math.round(Volume.inputVolume * 100)
                    iconColor: Theme.colors.text
                    suffixColor: Theme.colors.text
                    iconSize: Theme.dimensions.iconMedium
                    from: 0
                    to: 1
                    stepSize: 0.01
                    onValueChangedByUser: Volume.setInputVolume(value)
                    onIconClicked: Volume.toggleInputMute()

                    Binding on value {
                        value: Volume.inputVolume
                        when: !inputSlider.pressed
                        restoreMode: Binding.RestoreBinding
                    }
                }

                BaseSeparator { Layout.fillWidth: true; opacity: 0.1 }

                // Brightness
                BaseSlider {
                    id: brightnessSlider
                    Layout.fillWidth: true
                    trackHeight: 38
                    value: Display.brightness
                    icon: "light_mode"
                    suffix: Math.round(Display.brightness * 100)
                    iconColor: Theme.colors.text
                    suffixColor: Theme.colors.text
                    iconSize: Theme.dimensions.iconMedium
                    from: 0
                    to: 1
                    stepSize: 0.01
                    onValueChangedByUser: Display.setBrightness(value)

                    Binding on value {
                        value: Display.brightness
                        when: !brightnessSlider.pressed
                        restoreMode: Binding.RestoreBinding
                    }
                }
            }
        }
        }
    }

    Behavior on implicitHeight { BaseAnimation { speed: "fast" } }
}
