import QtQuick
//@ pragma UseQApplication
import Quickshell
import Quickshell.Io
import qs
import qs.services

ShellRoot {
    property var _display: Display
    property var _peripherals: Peripherals

    objectName: "shellRoot"

    FontLoader {
        source: Qt.resolvedUrl("assets/fonts/lucide.ttf")
    }

    IpcHandler {
        function toggle() { Modules.toggleModule("launcher"); }
        target: "launcher"
    }

    IpcHandler {
        function toggle() { Modules.toggleSettings(); }
        target: "settings"
    }

    IpcHandler {
        function toggle() { Modules.toggleModule("wallpaper"); }
        target: "wallpaper"
    }

    IpcHandler {
        function toggle() { Modules.toggleModule("power"); }
        target: "power"
    }

    IpcHandler {
        function reload(hard: bool): void { Quickshell.reload(hard); }
        target: "shell"
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
