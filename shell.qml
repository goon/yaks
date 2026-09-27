import QtQuick
//@ pragma UseQApplication
import Quickshell
import qs
import qs.services

ShellRoot {
    property var _stats: Stats
    property var _display: Display
    property var _cava: Cava

    objectName: "shellRoot"

    FontLoader {
        source: Qt.resolvedUrl("assets/fonts/lucide.ttf")
    }

    Commander {
        id: commander
    }


    Instantiator {
        model: Quickshell.screens

        WallpaperBackground {
            screen: modelData
        }
    }

    Instantiator {
        model: Quickshell.screens

        Bar {
            screen: modelData
        }
    }
}
