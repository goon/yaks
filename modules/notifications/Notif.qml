import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Notifications
import qs

BaseContainer {
    id: root

    implicitWidth: 400

    property var notificationManager: Notifications
    property int notifCount: notificationManager ? notificationManager.notificationHistory.count : 0

    ListView {
        id: list

        Layout.fillWidth: true
        implicitHeight: contentHeight
        model: root.notificationManager ? root.notificationManager.notificationHistory : null
        spacing: Globals.geometry.spacing.md
        interactive: false
        visible: root.notifCount > 0

        delegate: Column {
            width: ListView.view.width
            spacing: Globals.geometry.spacing.md

            NotificationCard {
                width: parent.width
                notification: modelData
                onRightClicked: {
                    if (modelData)
                        modelData.dismiss();
                }
            }

            BaseSeparator {
                width: parent.width
                visible: index < list.count - 1
            }
        }
    }

    // ── EMPTY STATE ──────────────────────────────────────────────
    Item {
        id: emptyPlaceholder
        Layout.fillWidth: true
        Layout.preferredHeight: root.notifCount === 0 ? 140 : 0
        visible: root.notifCount === 0
        opacity: visible ? 1 : 0
        Behavior on opacity {
            BaseMotion {}
        }
        Behavior on height {
            BaseMotion {}
        }
        clip: true

        ColumnLayout {
            anchors.centerIn: parent
            spacing: Globals.geometry.spacing.md

            BaseIcon {
                Layout.alignment: Qt.AlignHCenter
                icon: "bell-check"
                size: 32 * Globals.shellScale
                color: Globals.colors.muted
            }

            BaseText {
                Layout.alignment: Qt.AlignHCenter
                text: "CLEAR"
                weight: Globals.typography.weight.demi
                font.letterSpacing: 3
                color: Globals.colors.faint
            }
        }
    }
}
