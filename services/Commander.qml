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
            PopoutService.toggleLauncher();
        }

        target: "launcher"
    }

    // Settings
    IpcHandler {
        function toggle() {
            PopoutService.toggleSettings();
        }

        target: "settings"
    }

    // Wallpaper
    IpcHandler {
        function toggle() {
            PopoutService.toggleWallpaper();
        }

        function apply(path: string) {
            Wallpaper.applyWallpaper(path);
        }

        target: "wallpaper"
    }

    // Clipboard
    IpcHandler {
        function toggle() {
            PopoutService.toggleClipboard();
        }

        target: "clipboard"
    }

    // Theme
    IpcHandler {
        function apply(id: string) { ThemeService.setTheme(id); }
        target: "theme"
    }

    IpcHandler {
        function toggle() { PopoutService.toggleNotificationPopout(); }
        target: "notifications"
    }

    IpcHandler {
        function toggle() { PopoutService.toggleAudioPopout(); }
        target: "volume"
    }


    IpcHandler {
        function toggle() { PopoutService.toggleConnectivityPopout(); }
        target: "network"
    }

    IpcHandler {
        function toggle() { PopoutService.toggleConnectivityPopout(); }
        target: "bluetooth"
    }

    IpcHandler {
        function toggle() { PopoutService.togglePowerPopout(); }
        target: "power"
    }

    IpcHandler {
        function toggle() { PopoutService.toggleDashboardPopout(); }
        target: "dashboard"
    }
}
