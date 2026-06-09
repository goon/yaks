import QtQuick
import QtQuick.Layouts
import qs

Item {
    id: root
    implicitHeight: mainCol.implicitHeight
    implicitWidth: mainCol.implicitWidth

    GridLayout {
        id: mainCol
        anchors.fill: parent
        columns: 2
        rowSpacing: Theme.geometry.spacing.medium
        columnSpacing: Theme.geometry.spacing.medium

    // Wi-Fi
        BaseButton {
            buttonMode: "toggle"
            title: "Wi-Fi"
            subtitle: Network.wifiEnabled ? Network.ssid : "Off"
            icon: active ? "wifi" : "wifi_off"
            active: Network.wifiEnabled
            onClicked: IslandService.toggleNetworkPopout()
            onActionClicked: Network.toggleWifi()
        }
        
        // Bluetooth
        BaseButton {
            buttonMode: "toggle"
            title: "Bluetooth"
            subtitle: Bluetooth.powered ? (Bluetooth.connectedCount > 0 ? Bluetooth.connectedCount + " devices" : "On") : "Off"
            icon: active ? "bluetooth" : "bluetooth_disabled"
            active: Bluetooth.powered
            mirrored: true
            onClicked: IslandService.toggleBluetoothPopout()
            onActionClicked: Bluetooth.togglePower()
        }

        // DND
        BaseButton {
            buttonMode: "toggle"
            title: "Do Not Disturb"
            subtitle: Preferences.notificationMode === 1 ? "On" : "Off"
            icon: active ? "do_not_disturb_on" : "do_not_disturb_off"
            active: Preferences.notificationMode === 1
            hasChevron: false
            actionInteractive: false
            onClicked: Preferences.notificationMode = Preferences.notificationMode === 1 ? 0 : 1
        }


        // Screen Record
        BaseButton {
            buttonMode: "toggle"
            title: "Screen Record"
            subtitle: Recording.isRecording ? "Live" : "Ready"
            subtitleColor: Recording.isRecording ? Theme.base16.base08 : Theme.colors.muted
            icon: "stop_circle"
            active: Recording.isRecording
            actionColor: Theme.base16.base08
            hasChevron: false
            mirrored: true
            actionInteractive: false
            onClicked: Recording.isRecording ? Recording.stop() : Recording.start()
        }
    }
}
