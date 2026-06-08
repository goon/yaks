import QtQuick
import Quickshell
import Quickshell.Io
import qs.services

Item {
    // Add other IPC targets as needed...

    id: root

    // Launcher
    IpcHandler {
        function toggle() {
            IslandService.toggleLauncher();
        }

        target: "launcher"
    }

    // Settings
    IpcHandler {
        function toggle() {
            IslandService.toggleSettings();
        }

        function switchTo(pageName: string) {
            IslandService.toggleSettings(pageName);
        }

        target: "settings"
    }

    // Wallpaper
    IpcHandler {
        function toggle() {
            IslandService.toggleWallpaper();
        }

        function apply(path: string) {
            Wallpaper.applyWallpaper(path);
        }

        target: "wallpaper"
    }

    // Clipboard
    IpcHandler {
        function toggle() {
            IslandService.toggleClipboard();
        }

        target: "clipboard"
    }

    // Theme
    IpcHandler {
        function apply(id: string) { ThemeService.setTheme(id); }
        target: "theme"
    }

    IpcHandler {
        function toggle() { IslandService.toggleNotificationPopout(); }
        target: "notifications"
    }

    IpcHandler {
        function toggle() { IslandService.toggleAudioPopout(); }
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
}
