import QtQuick
import QtQuick.Effects
import qs

FocusScope {

    property string moduleState: "Closed"

    implicitWidth: carousel.naturalWidth
    implicitHeight: carousel.naturalHeight

    property Item initialFocusItem: carousel

    readonly property var carouselItem: carousel

    onModuleStateChanged: {
        if (moduleState === "Opening") {
            Wallpaper.ensureScanned();
            carousel.focusFirst();
            carousel.syncDirectory();
        }
    }

    Component.onCompleted: {
        Wallpaper.ensureScanned();
    }

    Item {
        anchors.fill: parent

        Rectangle {
            id: mask
            anchors.fill: parent
            radius: Globals.geometry.radius
            visible: false
            layer.enabled: true
            color: Globals.colors.text
        }

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

                onCloseRequested: Modules.closeAll()
            }
        }
    }
}
