import QtQuick
//@ pragma UseQApplication
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications
import qs
import qs.services

ShellRoot {
    // Instantiate background services for tracking
    property var _stats: Stats
    property var _gowall: Gowall
    property var _display: Display
    property var _cava: Cava

    objectName: "shellRoot"
    Component.onCompleted: {
        PopoutService.launcherLoader = launcherLoader;
        PopoutService.settingsLoader = settingsLoader;
        PopoutService.notificationPopoutLoader = notificationPopoutLoader;
        PopoutService.notificationManager = Notifications;
        PopoutService.audioPopoutLoader = audioPopoutLoader;
        PopoutService.powerPopoutLoader = powerPopoutLoader;
        PopoutService.networkPopoutLoader = networkPopoutLoader;
        PopoutService.bluetoothPopoutLoader = bluetoothPopoutLoader;
        PopoutService.dashboardPopoutLoader = dashboardPopoutLoader;
    }

    Commander {
        id: commander
    }

    NotificationOverlay {
        id: notificationOverlay
    }

    // Windows / Overlays
    BaseLazyLoader {
        id: launcherLoader
        source: Qt.resolvedUrl("modules/launcher/Launcher.qml")
    }

    BaseLazyLoader {
        id: settingsLoader
        source: Qt.resolvedUrl("modules/settings/Settings.qml")
    }

    BaseLazyLoader {
        id: dashboardPopoutLoader
        source: Qt.resolvedUrl("modules/dashboard/DashboardPopout.qml")
    }

    BaseLazyLoader {
        id: powerPopoutLoader
        source: Qt.resolvedUrl("modules/panels/PowerPopout.qml")
    }

    BaseLazyLoader {
        id: networkPopoutLoader
        source: Qt.resolvedUrl("modules/panels/connectivity/NetworkPopout.qml")
    }

    BaseLazyLoader {
        id: bluetoothPopoutLoader
        source: Qt.resolvedUrl("modules/panels/connectivity/BluetoothPopout.qml")
    }

    BaseLazyLoader {
        id: notificationPopoutLoader
        source: Qt.resolvedUrl("modules/panels/NotificationPopout.qml")
        onLoaded: {
            if (item) item.notificationManager = Notifications;
        }
    }

    BaseLazyLoader {
        id: audioPopoutLoader
        source: Qt.resolvedUrl("modules/panels/AudioPopout.qml")
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
