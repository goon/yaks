import QtQuick
import QtQuick.Layouts
import Quickshell
import qs
import qs.services

Item {
    
    property string panelState: "Closed"
    
    implicitWidth: 300 - (Globals.geometry.spacing.large * 2)
    implicitHeight: Math.max(0, Preferences.bar.height - (Globals.geometry.spacing.large * 2))
    
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
