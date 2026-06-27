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
        property color actionColor: Globals.colors.text

        // Simple pop on hover
        scale: containsMouse ? (pressed ? 0.95 : 1.1) : 1.0
        Behavior on scale { BaseAnimation { duration: Globals.animations.fast; easing.type: Easing.OutBack } }

        Item {
            anchors.centerIn: parent
            width: Globals.dimensions.iconLarge
            height: Globals.dimensions.iconLarge

            BaseIcon {
                anchors.centerIn: parent
                icon: btn.actionIcon
                size: Globals.dimensions.iconLarge
                color: btn.containsMouse ? btn.actionColor : Globals.colors.muted

                Behavior on color { BaseAnimation { } }
            }
        }
    }

    readonly property var _actions: [
        { icon: "power_settings_new", color: Globals.colors.error,     onClicked: function() { IslandService.closeAll(); Power.shutdown(); } },
        { icon: "restart_alt",        color: Globals.colors.text,      onClicked: function() { IslandService.closeAll(); Power.reboot(); } },
        { icon: "bedtime",            color: Globals.colors.info,      onClicked: function() { IslandService.closeAll(); Power.suspend(); } },
        { icon: "logout",             color: Globals.colors.secondary, onClicked: function() { IslandService.closeAll(); Power.logout(); } },
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
            Layout.topMargin: Globals.geometry.spacing.large
            Layout.bottomMargin: Globals.geometry.spacing.large
        }
        BaseSeparator {
            orientation: BaseSeparator.Vertical
            Layout.topMargin: Globals.geometry.spacing.large
            Layout.bottomMargin: Globals.geometry.spacing.large
        }
        BaseSeparator {
            orientation: BaseSeparator.Vertical
            Layout.topMargin: Globals.geometry.spacing.large
            Layout.bottomMargin: Globals.geometry.spacing.large
        }
    }
}
