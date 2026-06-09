import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import qs.services
import qs

FocusScope {
    id: root

    property string panelState: "Closed"

    implicitWidth: 1600
    implicitHeight: 600
    
    // Cleaned up legacy LauncherTab properties
    property Item initialFocusItem: carousel

    function activateCurrentItem() {
        if (carousel && carousel.model && carousel.model.length > 0 && carousel.currentIndex >= 0) {
            var path = carousel.model[carousel.currentIndex];
            if (path) {
                Wallpaper.setWallpaper(path);
                IslandService.closeAll();
            }
        }
    }

    onPanelStateChanged: {
        if (panelState === "Closed") {
            Wallpaper.ensureScanned();
            Wallpaper.shuffleWallpapers();
            carousel.setRandomIndex();
        }
    }

    Component.onCompleted: {
        Wallpaper.ensureScanned();
        Wallpaper.shuffleWallpapers();
        carousel.setRandomIndex();
    }
    
    // Main Layout
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 0
        spacing: Theme.geometry.spacing.medium

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            
            // Mask Source
            Rectangle {
                id: mask
                anchors.fill: parent
                radius: Theme.geometry.radius
                visible: false
                layer.enabled: true
                color: Theme.colors.text
            }

            // Masked Container
            Item {
                anchors.fill: parent
                layer.enabled: true
                layer.effect: MultiEffect {
                    maskEnabled: true
                    maskSource: mask
                }

                WallpaperCarousel {
                    id: carousel
                    anchors.fill: parent

                    borderRadius: Theme.geometry.radius
                    
                    centerWidth: parent.width * 0.5
                    sideWidth: ((parent.width * 0.5) / 2) - gap
                    
                    focus: true
                    
                    onCloseRequested: IslandService.closeAll()
                    
                    function safeIncrement() { if (incrementCurrentIndex) incrementCurrentIndex() }
                    function safeDecrement() { if (decrementCurrentIndex) decrementCurrentIndex() }
                }
            }
        }
    }
}
