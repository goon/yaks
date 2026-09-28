import QtQuick
import QtQuick.Layouts
import qs

Item {
    id: root

    Layout.fillWidth: true
    implicitHeight: mainCol.implicitHeight

    // ── SECTION MODEL ───────────────────────────────────────────────────

    readonly property var _sections: ["output", "input", "display"]

    readonly property Item hoveredSlider: {
        for (var i = 0; i < sectionRepeater.count; i++) {
            var item = sectionRepeater.itemAt(i);
            if (item && item.slider && item.slider.hovered) return item.slider;
        }
        return null;
    }

    function _setVolume(type, val) {
        if (type === "output") Volume.setVolume(val);
        else if (type === "input") Volume.setInputVolume(val);
        else if (type === "display") Display.setBrightness(val);
    }

    function _toggleMute(type) {
        if (type === "output") Volume.toggleMute();
        else if (type === "input") Volume.toggleInputMute();
    }

    ColumnLayout {
        id: mainCol
        anchors.fill: parent
        spacing: Globals.geometry.spacing.small

        Repeater {
            id: sectionRepeater
            model: root._sections

            delegate: Item {
                id: sectionItem
                required property int index
                required property string modelData
                readonly property Item slider: sectionSlider

                Layout.fillWidth: true
                implicitHeight: sectionCol.implicitHeight

                ColumnLayout {
                    id: sectionCol
                    anchors.fill: parent
                    spacing: Globals.geometry.spacing.small

                    BaseSeparator {
                        Layout.fillWidth: true
                        visible: index > 0
                        Layout.topMargin: Globals.geometry.spacing.small
                        Layout.bottomMargin: Globals.geometry.spacing.small
                    }

                    BaseSlider {
                        id: sectionSlider
                        Layout.fillWidth: true
                        Layout.leftMargin: Globals.geometry.spacing.medium
                        iconSize: Globals.dimensions.iconMedium
                        iconGap: Globals.geometry.spacing.large
                        icon: {
                            if (modelData === "output") return Volume.volumeIcon;
                            if (modelData === "input") return Volume.inputMuted ? "mic-off" : "mic-vocal";
                            return "sun";
                        }
                        muted: {
                            if (modelData === "output") return Volume.muted;
                            if (modelData === "input") return Volume.inputMuted;
                            return false;
                        }
                        stepSize: 0.01

                        Binding on value {
                            value: modelData === "output" ? Volume.volume
                                : (modelData === "input" ? Volume.inputVolume : Display.brightness)
                            when: !sectionSlider.pressed
                            restoreMode: Binding.RestoreBinding
                        }
                        onValueChangedByUser: root._setVolume(modelData, value)
                        onRightClicked: root._toggleMute(modelData)
                    }
                }
            }
        }
    }
}
