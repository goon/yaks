import QtQuick
import QtQuick.Layouts
import Quickshell
import qs

Item {
    
    // No inset shaved off the size: the capsule's `capsulePad` is the popout's
    // inset, so the toast fills the space it is given.
    implicitWidth: 300
    implicitHeight: Math.max(0, Preferences.bar.height)
    
    BaseSlider {
        id: slider
        anchors.fill: parent
        
        icon: Audio.volumeIcon
        muted: Audio.muted
        
        value: Audio.volume
        
        onValueChangedByUser: Audio.setVolume(value)
        onRightClicked: Audio.toggleMute()
        
        Binding on value {
            value: Audio.volume
            when: !slider.pressed
            restoreMode: Binding.RestoreBinding
        }
    }
}
