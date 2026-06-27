import QtQuick
import QtQuick.Layouts
import qs
import ".."

BaseContainer {
    id: root
    spacing: 0
    implicitHeight: 72
    implicitWidth: 380

    property string panelState: "Closed"

    component PowerButton: BaseButton {
        id: btn

        Layout.fillWidth: true
        Layout.fillHeight: true
        customRadius: 0
        hoverEnabled: false

        property string actionIcon: ""
        property color actionColor: Theme.colors.text

        // Simple pop on hover
        scale: containsMouse ? (pressed ? 0.95 : 1.1) : 1.0
        Behavior on scale { BaseAnimation { duration: Theme.animations.fast; easing.type: Easing.OutBack } }

        Item {
            anchors.centerIn: parent
            width: Theme.dimensions.iconLarge
            height: Theme.dimensions.iconLarge

            BaseIcon {
                anchors.centerIn: parent
                icon: btn.actionIcon
                size: Theme.dimensions.iconLarge
                color: btn.containsMouse ? btn.actionColor : Theme.colors.muted

                Behavior on color { BaseAnimation { } }
            }
        }
    }

    readonly property var _actions: [
        { icon: "power_settings_new", color: Theme.colors.error,     onClicked: function() { IslandService.closeAll(); Power.shutdown(); } },
        { icon: "restart_alt",        color: Theme.colors.text,      onClicked: function() { IslandService.closeAll(); Power.reboot(); } },
        { icon: "bedtime",            color: Theme.colors.info,      onClicked: function() { IslandService.closeAll(); Power.suspend(); } },
        { icon: "logout",             color: Theme.colors.secondary, onClicked: function() { IslandService.closeAll(); Power.logout(); } },
    ]

    RowLayout {
        id: layout
        Layout.fillWidth: true
        Layout.fillHeight: true
        spacing: 0

        Repeater {
            model: root._actions
            delegate: PowerButton {
                actionIcon: modelData.icon
                actionColor: modelData.color
                onClicked: modelData.onClicked()
            }
        }

        BaseSeparator {
            orientation: BaseSeparator.Vertical
            Layout.topMargin: Theme.geometry.spacing.large
            Layout.bottomMargin: Theme.geometry.spacing.large
        }
        BaseSeparator {
            orientation: BaseSeparator.Vertical
            Layout.topMargin: Theme.geometry.spacing.large
            Layout.bottomMargin: Theme.geometry.spacing.large
        }
        BaseSeparator {
            orientation: BaseSeparator.Vertical
            Layout.topMargin: Theme.geometry.spacing.large
            Layout.bottomMargin: Theme.geometry.spacing.large
        }
    }
}
