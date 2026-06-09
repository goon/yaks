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
                hoverColor: Theme.colors.background
                onClicked: expandedSide = (expandedSide === "output") ? "" : "output"

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: Theme.geometry.spacing.medium
                    anchors.rightMargin: Theme.geometry.spacing.large
                    spacing: Theme.geometry.spacing.medium

                    Item {
                        width: 48
                        height: 48
                        property bool active: !Volume.muted

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Volume.toggleMute()
                        }

                        property real breathScale: 1.0
                        SequentialAnimation {
                            loops: Animation.Infinite
                            running: parent.active
                            paused: !parent.active

                            NumberAnimation { target: parent; property: "breathScale"; to: 1.08; duration: 1200; easing.type: Easing.InOutSine }
                            NumberAnimation { target: parent; property: "breathScale"; to: 1.0;  duration: 1200; easing.type: Easing.InOutSine }
                        }

                        Canvas {
                            id: outRingCanvas
                            anchors.centerIn: parent
                            width: 48
                            height: 48
                            visible: parent.active

                            property int cornerRadius: Theme.geometry.radius
                            onCornerRadiusChanged: requestPaint()

                            onPaint: {
                                var ctx = getContext("2d");
                                ctx.clearRect(0, 0, width, height);
                                var lw = 1.5;
                                var bw = 36, bh = 36;
                                var bx = (width - bw) / 2;
                                var by = (height - bh) / 2;
                                var r = Math.min(Theme.geometry.radius, bw / 2, bh / 2);
                                ctx.beginPath();
                                ctx.moveTo(bx + r, by);
                                ctx.lineTo(bx + bw - r, by);
                                ctx.arcTo(bx + bw, by, bx + bw, by + r, r);
                                ctx.lineTo(bx + bw, by + bh - r);
                                ctx.arcTo(bx + bw, by + bh, bx + bw - r, by + bh, r);
                                ctx.lineTo(bx + r, by + bh);
                                ctx.arcTo(bx, by + bh, bx, by + bh - r, r);
                                ctx.lineTo(bx, by + r);
                                ctx.arcTo(bx, by, bx + r, by, r);
                                ctx.closePath();
                                var grad = ctx.createLinearGradient(0, 0, width, height);
                                grad.addColorStop(0.0, Theme.colors.primary);
                                grad.addColorStop(1.0, Theme.colors.secondary);
                                ctx.strokeStyle = grad;
                                ctx.lineWidth = lw;
                                ctx.stroke();
                            }

                            onWidthChanged: requestPaint()
                            onHeightChanged: requestPaint()
                        }

                        Rectangle {
                            width: 36
                            height: 36
                            radius: Theme.geometry.radius
                            anchors.centerIn: parent
                            scale: parent.breathScale
                            color: parent.active ? Theme.alpha(Theme.colors.primary, 0.15) : Theme.alpha(Theme.colors.text, 0.1)
                            
                            BaseIcon {
                                anchors.centerIn: parent
                                icon: Volume.volumeIcon
                                size: Theme.dimensions.iconBase
                                color: parent.parent.active ? Theme.colors.primary : Theme.colors.text
                            }
                        }
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
                hoverColor: Theme.colors.background
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

                    Item {
                        width: 48
                        height: 48
                        property bool active: !Volume.inputMuted

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Volume.toggleInputMute()
                        }

                        property real breathScale: 1.0
                        SequentialAnimation {
                            loops: Animation.Infinite
                            running: parent.active
                            paused: !parent.active

                            NumberAnimation { target: parent; property: "breathScale"; to: 1.08; duration: 1200; easing.type: Easing.InOutSine }
                            NumberAnimation { target: parent; property: "breathScale"; to: 1.0;  duration: 1200; easing.type: Easing.InOutSine }
                        }

                        Canvas {
                            id: inRingCanvas
                            anchors.centerIn: parent
                            width: 48
                            height: 48
                            visible: parent.active

                            property int cornerRadius: Theme.geometry.radius
                            onCornerRadiusChanged: requestPaint()

                            onPaint: {
                                var ctx = getContext("2d");
                                ctx.clearRect(0, 0, width, height);
                                var lw = 1.5;
                                var bw = 36, bh = 36;
                                var bx = (width - bw) / 2;
                                var by = (height - bh) / 2;
                                var r = Math.min(Theme.geometry.radius, bw / 2, bh / 2);
                                ctx.beginPath();
                                ctx.moveTo(bx + r, by);
                                ctx.lineTo(bx + bw - r, by);
                                ctx.arcTo(bx + bw, by, bx + bw, by + r, r);
                                ctx.lineTo(bx + bw, by + bh - r);
                                ctx.arcTo(bx + bw, by + bh, bx + bw - r, by + bh, r);
                                ctx.lineTo(bx + r, by + bh);
                                ctx.arcTo(bx, by + bh, bx, by + bh - r, r);
                                ctx.lineTo(bx, by + r);
                                ctx.arcTo(bx, by, bx + r, by, r);
                                ctx.closePath();
                                var grad = ctx.createLinearGradient(0, 0, width, height);
                                grad.addColorStop(0.0, Theme.colors.primary);
                                grad.addColorStop(1.0, Theme.colors.secondary);
                                ctx.strokeStyle = grad;
                                ctx.lineWidth = lw;
                                ctx.stroke();
                            }

                            onWidthChanged: requestPaint()
                            onHeightChanged: requestPaint()
                        }

                        Rectangle {
                            width: 36
                            height: 36
                            radius: Theme.geometry.radius
                            anchors.centerIn: parent
                            scale: parent.breathScale
                            color: parent.active ? Theme.alpha(Theme.colors.primary, 0.15) : Theme.alpha(Theme.colors.text, 0.1)
                            
                            BaseIcon {
                                anchors.centerIn: parent
                                icon: Volume.inputMuted ? "mic_off" : "mic"
                                size: Theme.dimensions.iconBase
                                color: parent.parent.active ? Theme.colors.primary : Theme.colors.text
                            }
                        }
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
