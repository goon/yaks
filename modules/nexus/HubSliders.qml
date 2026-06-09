import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs

BaseBlock {
    id: root

    Layout.fillWidth: true
    spacing: Theme.geometry.spacing.large
    paddingVertical: Theme.geometry.spacing.large

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

    BaseSeparator { Layout.fillWidth: true; opacity: 0.1 }

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
}
