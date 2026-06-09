import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Notifications
import QtQuick.Effects
import qs

BaseBlock {
    id: root

    property var notificationManager: Notifications
    property var expandedStates: ({})
    property var groupedModel: []
    property int notifCount: notificationManager ? notificationManager.notificationHistory.count : 0

    onNotificationManagerChanged: updateGroupedModel()

    function updateGroupedModel() {
        if (!notificationManager) {
            root.groupedModel = [];
            return ;
        }
        const history = notificationManager.notificationHistory;
        const groups = {
        };
        const result = [];
        for (let i = 0; i < history.count; i++) {
            const item = history.get(i);
            const appName = item.modelData.appName || "Unknown";
            if (!groups[appName]) {
                groups[appName] = {
                    "appName": appName,
                    "notifications": [],
                    "latest": item.receivedAt
                };
                result.push(groups[appName]);
            }
            groups[appName].notifications.push(item);
        }
        root.groupedModel = result;
    }

    Layout.fillWidth: true
    backgroundColor: Theme.alpha(Theme.colors.surface, Theme.opacity.surface)
    spacing: Theme.geometry.spacing.large
    paddingVertical: Theme.geometry.spacing.large

    Component.onCompleted: updateGroupedModel()

    Connections {
        function onCountChanged() {
            root.updateGroupedModel();
        }

        target: root.notificationManager ? root.notificationManager.notificationHistory : null
    }

    RowLayout {
        Layout.fillWidth: true
        visible: root.notifCount > 0
        spacing: 0

        // Left balancing item (matches width of buttons on the right)
        Item {
            Layout.preferredWidth: headerButtons.implicitWidth
            Layout.fillHeight: true
        }

        // Styled Label
        BaseText {
            Layout.fillWidth: true
            text: "NOTIFICATIONS (" + root.notifCount + ")"
            color: Theme.colors.muted
            pixelSize: Theme.typography.size.base
            weight: Theme.typography.weights.bold
            horizontalAlignment: Text.AlignHCenter
            font.letterSpacing: 2
        }

        // Header Actions
        RowLayout {
            id: headerButtons
            spacing: Theme.geometry.spacing.small

            BaseButton {
                icon: "clear_all"
                size: Theme.dimensions.iconMedium
                hoverColor: Theme.alpha(Theme.colors.error, 0.1)
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
    }

    // Notifications List
    ListView {
        id: list

        Layout.fillWidth: true
        implicitHeight: contentHeight
        model: root.groupedModel
        spacing: Theme.geometry.spacing.medium
        interactive: false
        visible: root.notifCount > 0

        delegate: Column {
            id: groupDelegate

            property var groupData: modelData
            property bool isStack: groupData.notifications.length > 1
            property bool expanded: root.expandedStates[groupData.appName] === true

            width: ListView.view.width
            spacing: Theme.geometry.spacing.small // Tighter gap within a group stack

            // Stack/Header
            Item {
                width: parent.width
                height: headerCard.implicitHeight + (isStack && !expanded ? 8 : 0)

                Behavior on height { BaseAnimation { speed: "fast" } }

                // Stack Background (Shadow/Cards behind) - Single Layer
                Rectangle {
                    visible: opacity > 0
                    opacity: isStack && !expanded ? 1 : 0
                    width: parent.width - 24
                    height: headerCard.implicitHeight
                    anchors.horizontalCenter: parent.horizontalCenter
                    z: -1
                    y: 8
                    color: Theme.alpha(Theme.colors.base, Theme.opacity.surface)
                    radius: Theme.geometry.radius
                    border.color: Theme.alpha(Theme.colors.base, Theme.opacity.surface)
                    border.width: 1

                    Behavior on opacity { BaseAnimation { speed: "fast" } }
                }

                NotificationCard {
                    id: headerCard
                    
                    width: parent.width
                    z: 1
                    notification: groupData.notifications[0].modelData
                    time: groupData.notifications[0].receivedAt
                    borderEnabled: false
                    padding: 0
                    showCloseButton: false
                    progress: 0
                    backgroundColor: Theme.alpha(Theme.colors.background, Theme.opacity.surface)
                    onClicked: {
                        if (!isStack) return;
                        var states = root.expandedStates;
                        states[groupData.appName] = !groupDelegate.expanded;
                        root.expandedStates = Object.assign({}, states);
                    }
                    onRightClicked: {
                        const notifs = groupData.notifications;
                        if (!expanded && isStack) {
                            for (let i = notifs.length - 1; i >= 0; i--) {
                                if (notifs[i].modelData)
                                    notifs[i].modelData.dismiss();
                            }
                        } else {
                            if (notifs[0].modelData)
                                notifs[0].modelData.dismiss();
                        }
                    }
                }
            }

            // Expanded Notifications
            Column {
                width: parent.width
                visible: height > 0
                clip: true
                spacing: Theme.geometry.spacing.small
                opacity: expanded ? 1 : 0
                height: expanded ? implicitHeight : 0

                Behavior on height { BaseAnimation { speed: "normal" } }
                Behavior on opacity { BaseAnimation { speed: "normal" } }

                Repeater {
                    model: isStack ? groupData.notifications.slice(1) : 0

                    delegate: NotificationCard {
                        width: parent.width
                        notification: modelData.modelData
                        time: modelData.receivedAt
                        borderEnabled: false
                        padding: 0
                        showCloseButton: false
                        backgroundColor: Theme.alpha(Theme.colors.base, Theme.opacity.surface)
                        onRightClicked: {
                            if (modelData.modelData)
                                modelData.modelData.dismiss();
                        }
                    }
                }

                Item {
                    width: parent.width
                    height: 4
                }
            }
        }
    }

    // EMPTY STATE PLACEHOLDERS
    Item {
        id: emptyPlaceholder
        Layout.fillWidth: true
        Layout.preferredHeight: root.notifCount === 0 ? 250 : 0
        visible: root.notifCount === 0
        opacity: visible ? 1 : 0
        Behavior on opacity { BaseAnimation { speed: "normal" } }
        Behavior on Layout.preferredHeight { BaseAnimation { speed: "normal" } }
        clip: true

        // STYLE 0: Bouncing "DVD Logo" Bell
        Item {
            anchors.fill: parent
            
            ColumnLayout {
                anchors.centerIn: parent
                spacing: -8 // Tight vertical spacing for editorial look
                
                BaseText {
                    text: "you're"
                    color: Theme.colors.muted
                    pixelSize: Theme.typography.size.large
                    font.italic: true
                    Layout.alignment: Qt.AlignLeft
                    Layout.leftMargin: 8
                }
                
                Item {
                    width: 320
                    height: 64
                    Layout.alignment: Qt.AlignHCenter
                    
                    BaseText {
                        anchors.fill: parent
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        text: "ALL CAUGHT"
                        color: Theme.colors.text
                        opacity: 0.4
                        pixelSize: 48
                        weight: Theme.typography.weights.bold
                        font.letterSpacing: -1
                    }
                    
                    BaseText {
                        id: pulseText
                        anchors.fill: parent
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        text: "ALL CAUGHT"
                        color: Theme.colors.primary
                        opacity: 0.0
                        pixelSize: 48
                        weight: Theme.typography.weights.bold
                        font.letterSpacing: -1
                        
                        SequentialAnimation {
                            loops: Animation.Infinite
                            running: emptyPlaceholder.visible
                            
                            NumberAnimation { target: pulseText; property: "opacity"; to: 1.0; duration: 2000; easing.type: Easing.InOutQuad }
                            ColorAnimation { target: pulseText; property: "color"; to: Theme.colors.secondary; duration: 2000; easing.type: Easing.InOutQuad }
                            ColorAnimation { target: pulseText; property: "color"; to: Theme.colors.primary; duration: 2000; easing.type: Easing.InOutQuad }
                            NumberAnimation { target: pulseText; property: "opacity"; to: 0.0; duration: 2000; easing.type: Easing.InOutQuad }
                            PauseAnimation { duration: 1000 }
                        }
                    }
                }
                
                BaseText {
                    text: "up."
                    color: Theme.colors.primary
                    pixelSize: Theme.typography.size.large
                    weight: Theme.typography.weights.light
                    Layout.alignment: Qt.AlignRight
                    Layout.rightMargin: 8
                }
            }

            Canvas {
                id: bounceContainer
                z: -1 // CRITICAL: Explicitly layer the bell behind the text ColumnLayout
                width: Theme.dimensions.iconExtraLarge
                height: Theme.dimensions.iconExtraLarge
                
                property real vx: 1.5
                property real vy: 1.2
                
                x: parent.width / 2
                y: parent.height / 2
                
                property real offset: 0
                
                NumberAnimation on offset {
                    loops: Animation.Infinite
                    from: 0
                    to: 1
                    duration: 2000
                    running: emptyPlaceholder.visible
                }
                
                onOffsetChanged: requestPaint()
                
                RotationAnimation on rotation {
                    loops: Animation.Infinite
                    from: 0
                    to: 360
                    duration: 4000
                    running: emptyPlaceholder.visible
                }
                
                onPaint: {
                    var ctx = getContext("2d");
                    ctx.clearRect(0, 0, width, height);
                    
                    // Oscillating gradient vector to create a smooth, continuous flow
                    var gradOffset = Math.sin(offset * Math.PI * 2);
                    var gradX1 = (width / 2) + (width / 2) * gradOffset;
                    var gradX2 = (width / 2) - (width / 2) * gradOffset;
                    
                    var grad = ctx.createLinearGradient(gradX1, 0, gradX2, height);
                    grad.addColorStop(0.0, Theme.colors.primary);
                    grad.addColorStop(1.0, Theme.colors.secondary);
                    
                    ctx.fillStyle = grad;
                    // Note: Theme.typography.iconFamily provides the Material font
                    ctx.font = Theme.dimensions.iconExtraLarge + "px \"" + Theme.typography.iconFamily + "\"";
                    ctx.textAlign = "center";
                    ctx.textBaseline = "middle";
                    ctx.globalAlpha = 0.7; // Dim slightly per request
                    ctx.fillText("notifications", width/2, height/2);
                }
                
                Timer {
                    interval: 16
                    running: emptyPlaceholder.visible
                    repeat: true
                    onTriggered: {
                        var nx = bounceContainer.x + bounceContainer.vx;
                        var ny = bounceContainer.y + bounceContainer.vy;
                        
                        if (nx <= 0 || nx + bounceContainer.width >= bounceContainer.parent.width) {
                            bounceContainer.vx *= -1;
                            nx = Math.max(0, Math.min(nx, bounceContainer.parent.width - bounceContainer.width));
                        }
                        if (ny <= 0 || ny + bounceContainer.height >= bounceContainer.parent.height) {
                            bounceContainer.vy *= -1;
                            ny = Math.max(0, Math.min(ny, bounceContainer.parent.height - bounceContainer.height));
                        }
                        
                        bounceContainer.x = nx;
                        bounceContainer.y = ny;
                    }
                }
            }
        }

    }
}
