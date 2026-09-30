import QtQuick
import Quickshell
import Quickshell.Io
import qs.services

Item {
    // Add other IPC targets as needed...

    id: root

    IpcHandler {
        function toggle() {
            IslandService.toggleLauncher();
        }

        target: "launcher"
    }

    IpcHandler {
        function toggle() {
            IslandService.toggleSettings();
        }

        function switchTo(pageName: string) {
            IslandService.toggleSettings(pageName);
        }

        target: "settings"
    }

    IpcHandler {
        function toggle() {
            IslandService.toggleWallpaper();
        }

        function apply(path: string) {
            Wallpaper.setWallpaper(path);
        }

        target: "wallpaper"
    }

    IpcHandler {
        function apply() {
            Theme.requestApply("manual");
        }
        target: "theme"
    }

    IpcHandler {
        function toggle() { IslandService.toggleNotificationsPopout(); }
        target: "notifications"
    }


    IpcHandler {
        function toggle() { IslandService.toggleNetworkPopout(); }
        target: "network"
    }

    IpcHandler {
        function toggle() { IslandService.toggleBluetoothPopout(); }
        target: "bluetooth"
    }

    IpcHandler {
        function toggle() { IslandService.togglePowerPopout(); }
        target: "power"
    }



    IpcHandler {
        function reload(hard: bool): void {
            Quickshell.reload(hard);
        }
        target: "shell"
    }
}
