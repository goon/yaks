import QtQuick
import qs

ListView {
    id: root

    // Common Configuration
    spacing: Globals.geometry.spacing.large
    activeFocusOnTab: false
    
    // Disable highlight animations for snappier feel
    highlightMoveDuration: 0
    highlightResizeDuration: 0
}
