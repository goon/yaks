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
            Wallpaper.applyWallpaper(path);
        }

        target: "wallpaper"
    }

    IpcHandler {
        function apply(id: string) { Theme.setTheme(id); }
        target: "theme"
    }

    IpcHandler {
        function toggle() { IslandService.toggleNotificationsPopout(); }
        target: "notifications"
    }

    IpcHandler {
        function toggle() { IslandService.toggleMixerPopout(); }
        target: "volume"
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
        function toggle() { IslandService.toggleDashboardPopout(); }
        target: "dashboard"
    }



    IpcHandler {
        function reload(hard: bool): void {
            Quickshell.reload(hard);
        }
        target: "shell"
    }
}
