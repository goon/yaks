import QtQuick
import QtQuick.Layouts
import Quickshell
import qs
import qs.services

Item {
    id: root
    
    property string panelState: "Closed"
    
    implicitWidth: 300 - (Theme.geometry.spacing.large * 2)
    implicitHeight: Math.max(0, Preferences.barHeight - (Theme.geometry.spacing.large * 2))
    
    BaseSlider {
        id: slider
        anchors.fill: parent
        
        trackHeight: height
        trackColor: Theme.alpha(Theme.colors.surface, Theme.opacity.surface)
        
        icon: Volume.volumeIcon
        suffix: Volume.volumePercent + "%"
        iconColor: Theme.colors.text
        suffixColor: Theme.colors.text
        iconSize: Theme.dimensions.iconMedium
        
        from: 0
        to: 1
        value: Volume.volume
        
        // Crucial: slider MUST be interactive for the handle/knob (and its icon/suffix) to be visible!
        interactive: true
        
        onValueChangedByUser: Volume.setVolume(value)
        onIconClicked: Volume.toggleMute()
        
        Binding on value {
            value: Volume.volume
            when: !slider.pressed
            restoreMode: Binding.RestoreBinding
        }
    }
}
