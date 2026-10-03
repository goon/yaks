import QtQuick
import QtQuick.Layouts
import Quickshell
import qs

Item {
    
    // The toast replaces the bar face, so the island must not resize when it
    // opens: the capsule is `implicitHeight + capsulePad * 2`, so the content
    // height is the bar's height minus the capsule's own inset.
    implicitWidth: 300
    implicitHeight: Math.max(0, Preferences.bar.height - Globals.geometry.spacing.xl * 2)
    
    BaseSlider {
        id: slider
        anchors.fill: parent
        
        icon: Audio.volumeIcon
        muted: Audio.muted
        iconGap: Globals.geometry.spacing.md
        
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
