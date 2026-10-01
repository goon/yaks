import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Notifications
import qs

BaseContainer {
    id: root

    implicitWidth: 460

    readonly property int _pulseMs: 2000
    readonly property int _pulsePauseMs: 1000

    property var notificationManager: Notifications
    property int notifCount: notificationManager ? notificationManager.notificationHistory.count : 0

    spacing: Globals.geometry.spacing.md

    ColumnLayout {
        Layout.fillWidth: true
        visible: root.notifCount > 0

        RowLayout {
            Layout.fillWidth: true
            Layout.bottomMargin: Globals.geometry.spacing.md
            spacing: Globals.geometry.spacing.xs

            BaseHeader {
                text: String(root.notifCount)
            }

            Item { Layout.fillWidth: true }

            BaseButton {
                icon: "trash-2"
                hoverColor: "transparent"
                onClicked: {
                    if (root.notificationManager) {
                        const model = root.notificationManager.notificationHistory;
                        for (let i = model.count - 1; i >= 0; i--) {
                            let notif = model.get(i).modelData;
                            if (notif)
                                notif.dismiss();
                        }
                    }
                }
                enabled: root.notificationManager && root.notificationManager.notificationHistory.count > 0
                opacity: enabled ? 1 : 0.3
            }
        }

        BaseSeparator {
            Layout.fillWidth: true
        }
    }

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
                time: receivedAt
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

    // ── EMPTY STATE PLACEHOLDERS ─────────────────────────────────────
    Item {
        id: emptyPlaceholder
        Layout.fillWidth: true
        Layout.preferredHeight: root.notifCount === 0 ? 140 : 0
        visible: root.notifCount === 0
        opacity: visible ? 1 : 0
        Behavior on opacity { BaseMotion { } }
        Behavior on height { BaseMotion { } }
        clip: true

        Item {
            anchors.fill: parent

            ColumnLayout {
                anchors.centerIn: parent
                spacing: -8 // Tight vertical spacing for editorial look

                BaseText {
                    text: "you're"
                    muted: true
                    pixelSize: Globals.typography.size.lg
                    font.italic: true
                    Layout.alignment: Qt.AlignLeft
                    Layout.leftMargin: Globals.geometry.spacing.sm
                }

                Item {
                    width: parent.width
                    height: 64 * Globals.shellScale
                    Layout.alignment: Qt.AlignHCenter

                    BaseText {
                        anchors.fill: parent
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        text: "ALL CAUGHT"
                        opacity: 0.4
                        pixelSize: Globals.typography.size.xl * 3
                        weight: Globals.typography.weight.bold
                        font.letterSpacing: -1
                    }

                    BaseText {
                        id: pulseText
                        anchors.fill: parent
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        text: "ALL CAUGHT"
                        color: Globals.colors.primary
                        opacity: 0.0
                        pixelSize: Globals.typography.size.xl * 3
                        weight: Globals.typography.weight.bold
                        font.letterSpacing: -1

                        SequentialAnimation {
                            loops: Animation.Infinite
                            running: emptyPlaceholder.visible

                            NumberAnimation { target: pulseText; property: "opacity"; to: 1.0; duration: root._pulseMs; easing.type: Easing.InOutQuad }
                            ColorAnimation { target: pulseText; property: "color"; to: Globals.colors.secondary; duration: root._pulseMs; easing.type: Easing.InOutQuad }
                            ColorAnimation { target: pulseText; property: "color"; to: Globals.colors.primary; duration: root._pulseMs; easing.type: Easing.InOutQuad }
                            NumberAnimation { target: pulseText; property: "opacity"; to: 0.0; duration: root._pulseMs; easing.type: Easing.InOutQuad }
                            PauseAnimation { duration: root._pulsePauseMs }
                        }
                    }
                }

                BaseText {
                    text: "up."
                    color: Globals.colors.primary
                    pixelSize: Globals.typography.size.lg
                    Layout.alignment: Qt.AlignRight
                    Layout.rightMargin: Globals.geometry.spacing.sm
                }
            }
        }

    }
}
