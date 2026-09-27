import QtQuick
import qs

ListView {
    id: root

    spacing: Globals.geometry.spacing.large
    activeFocusOnTab: false
    
    // Disable highlight animations for snappier feel
    highlightMoveDuration: 0
    highlightResizeDuration: 0
}
