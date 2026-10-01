import QtQuick
//@ pragma UseQApplication
import Quickshell
import Quickshell.Io
import qs
import qs.services

ShellRoot {
    property var _display: Display

    objectName: "shellRoot"

    FontLoader {
        source: Qt.resolvedUrl("assets/fonts/lucide.ttf")
    }

    IpcHandler {
        function toggle() { Panels.togglePanel("launcher"); }
        target: "launcher"
    }

    IpcHandler {
        function toggle() { Panels.toggleSettings(); }
        target: "settings"
    }

    IpcHandler {
        function toggle() { Panels.togglePanel("wallpaper"); }
        target: "wallpaper"
    }

    IpcHandler {
        function toggle() { Panels.togglePanel("power"); }
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
