import QtQuick
import QtQuick.Layouts
import Quickshell
import qs
import qs.services

Item {
    id: root
    
    property string panelState: "Closed"
    
    implicitWidth: 300 - (Theme.geometry.spacing.large * 2)
    implicitHeight: Math.max(0, Preferences.bar.height - (Theme.geometry.spacing.large * 2))
    
    BaseSlider {
        id: slider
        anchors.fill: parent
        
        trackHeight: height
        trackColor: Theme.alpha(Theme.colors.surface, 0.22)
        
        icon: Volume.volumeIcon
        suffix: Volume.volumePercent + "%"
        muted: Volume.muted
        
        value: Volume.volume
        
        onValueChangedByUser: Volume.setVolume(value)
        onRightClicked: Volume.toggleMute()
        
        Binding on value {
            value: Volume.volume
            when: !slider.pressed
            restoreMode: Binding.RestoreBinding
        }
    }
}
