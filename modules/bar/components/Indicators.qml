import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Services.SystemTray
import qs
import qs.services

Item {
    id: root

    property var barWindow: null

    property Component trayMenuComponent: Component {
        TrayPopout {}
    }

    Layout.alignment: Qt.AlignVCenter
    Layout.fillWidth: false
    implicitWidth: background.implicitWidth
    implicitHeight: Theme.dimensions.barItemHeight

    readonly property int itemWidth: Theme.dimensions.iconBase + 8
    readonly property int spacing: Theme.geometry.spacing.small

    readonly property bool isTrayVisible: Preferences.indicatorsShowTray && TrayService.itemCount > 0

    // Calculate final target width for each key
    function getItemWidth(key) {
        if (key === "tray") {
            if (!isTrayVisible) return 0;
            if (!Preferences.indicatorsTrayExpanded) return 32;
            return 32 + spacing + (TrayService.itemCount * 24) + ((TrayService.itemCount - 1) * spacing);
        }
        if (key === "volume") {
            if (!Preferences.indicatorsShowVolume) return 0;
            return root.itemWidth;
        }
        return 32;
    }

    // Filter to get only visible draggable items in order
    readonly property var visibleKeys: {
        let keys = [];
        for (let i = 0; i < Preferences.indicatorsOrder.length; i++) {
            let key = Preferences.indicatorsOrder[i];
            if (key === "wifi" && Preferences.indicatorsShowWifi) keys.push(key);
            if (key === "bluetooth" && Preferences.indicatorsShowBluetooth) keys.push(key);
            if (key === "volume" && Preferences.indicatorsShowVolume) keys.push(key);
            if (key === "notifications" && Preferences.indicatorsShowNotifications) keys.push(key);
        }
        return keys;
    }

    // Total content width based on animating widths of item components
    readonly property int contentWidth: {
        let w = 0;
        let hasVisibleItem = false;

        if (isTrayVisible) {
            w += trayItem.width;
            hasVisibleItem = true;
        }

        for (let i = 0; i < visibleKeys.length; i++) {
            let k = visibleKeys[i];
            let itemW = 0;
            if (k === "wifi") itemW = wifiItem.width;
            else if (k === "bluetooth") itemW = bluetoothItem.width;
            else if (k === "volume") itemW = volumeItem.width;
            else if (k === "notifications") itemW = notificationsItem.width;

            if (itemW > 0) {
                if (hasVisibleItem) w += spacing;
                w += itemW;
                hasVisibleItem = true;
            }
        }
        return w;
    }

    // Get current animating X coordinate for positioning items in flow
    function getActualX(key) {
        if (key === "tray") return 0;

        let x = 0;
        if (isTrayVisible) {
            x += trayItem.width + spacing;
        }

        let idx = visibleKeys.indexOf(key);
        if (idx === -1) return x;

        for (let i = 0; i < idx; i++) {
            let k = visibleKeys[i];
            if (k === "wifi") x += wifiItem.width + spacing;
            else if (k === "bluetooth") x += bluetoothItem.width + spacing;
            else if (k === "volume") x += volumeItem.width + spacing;
            else if (k === "notifications") x += notificationsItem.width + spacing;
        }
        return x;
    }

    // Get static target position for drag and swap math
    function getTargetX(key) {
        if (key === "tray") return 0;

        let x = 0;
        if (isTrayVisible) {
            x += getItemWidth("tray") + spacing;
        }

        let idx = visibleKeys.indexOf(key);
        if (idx === -1) return x;

        for (let i = 0; i < idx; i++) {
            let k = visibleKeys[i];
            x += getItemWidth(k) + spacing;
        }
        return x;
    }

    BaseBlock {
        id: background

        anchors.fill: parent
        backgroundColor: Theme.colors.transparent
        paddingVertical: 0
        paddingHorizontal: Theme.geometry.spacing.small
        implicitHeight: Theme.dimensions.barItemHeight
        hoverEnabled: false
        clickable: false

        Item {
            id: container
            implicitWidth: root.contentWidth
            implicitHeight: Theme.dimensions.barItemHeight
            height: parent.height

            // Non-draggable static System Tray item anchored to the left (x = 0)
            Item {
                id: trayItem
                visible: root.isTrayVisible
                height: parent.height
                x: 0
                clip: true

                width: visible ? getItemWidth("tray") : 0
                Behavior on width {
                    BaseAnimation {
                        duration: Theme.animations.normal
                    }
                }

                Loader {
                    id: trayLoader
                    anchors.fill: parent
                    sourceComponent: trayComponent
                }
            }

            DraggableStatusItem {
                id: wifiItem
                itemKey: "wifi"
                contentComponent: wifiComponent
            }

            DraggableStatusItem {
                id: bluetoothItem
                itemKey: "bluetooth"
                contentComponent: bluetoothComponent
            }

            DraggableStatusItem {
                id: notificationsItem
                itemKey: "notifications"
                contentComponent: notificationsComponent
            }

            DraggableStatusItem {
                id: volumeItem
                itemKey: "volume"
                contentComponent: volumeComponent
            }
        }
    }

    component DraggableStatusItem: Item {
        id: itemRoot

        required property string itemKey
        required property Component contentComponent
        readonly property alias loaderItem: contentLoader.item

        readonly property bool isVisible: {
            if (itemKey === "wifi") return Preferences.indicatorsShowWifi;
            if (itemKey === "bluetooth") return Preferences.indicatorsShowBluetooth;
            if (itemKey === "volume") return Preferences.indicatorsShowVolume;
            if (itemKey === "notifications") return Preferences.indicatorsShowNotifications;
            return false;
        }

        visible: isVisible
        height: parent.height
        
        // Define animating width centered on the item's state width
        width: isVisible ? getItemWidth(itemKey) : 0
        Behavior on width {
            BaseAnimation {
                duration: Theme.animations.normal
            }
        }

        readonly property int targetX: getTargetX(itemKey)
        readonly property bool isDragging: dragArea.drag.active

        // Follow the actual coordinates when not dragged
        x: isDragging ? x : getActualX(itemKey)

        onIsDraggingChanged: {
            if (isDragging) {
                PopoutService.closeAll();
            }
        }

        Loader {
            id: contentLoader
            anchors.fill: parent
            sourceComponent: contentComponent

            // Pass containsMouse to the child
            property bool containsMouse: dragArea.containsMouse

            onLoaded: {
                if (itemKey === "wifi") PopoutService.networkItem = item;
                else if (itemKey === "bluetooth") PopoutService.bluetoothItem = item;
                else if (itemKey === "volume") PopoutService.volumeItem = item;
                else if (itemKey === "notifications") PopoutService.notificationsItem = item;
            }
        }

        Component.onDestruction: {
            if (itemKey === "wifi") {
                if (PopoutService.networkItem === contentLoader.item)
                    PopoutService.networkItem = null;
            } else if (itemKey === "bluetooth") {
                if (PopoutService.bluetoothItem === contentLoader.item)
                    PopoutService.bluetoothItem = null;
            } else if (itemKey === "volume") {
                if (PopoutService.volumeItem === contentLoader.item)
                    PopoutService.volumeItem = null;
            } else if (itemKey === "notifications") {
                if (PopoutService.notificationsItem === contentLoader.item)
                    PopoutService.notificationsItem = null;
            }
        }

        Timer {
            id: hoverTimer
            interval: 250
            repeat: false
            onTriggered: {
                if (itemRoot.isDragging) return;
                if (itemKey === "wifi") PopoutService.openNetworkPopout();
                else if (itemKey === "bluetooth") PopoutService.openBluetoothPopout();
                else if (itemKey === "volume") PopoutService.openAudioPopout();
                else if (itemKey === "notifications") PopoutService.openNotificationPopout();
            }
        }

        Connections {
            target: dragArea
            function onContainsMouseChanged() {
                if (dragArea.containsMouse && Preferences.popoutTrigger === 1 && !itemRoot.isDragging) {
                    hoverTimer.restart();
                } else {
                    hoverTimer.stop();
                }
            }
        }

        MouseArea {
            id: dragArea
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            cursorShape: containsMouse ? Qt.PointingHandCursor : Qt.ArrowCursor

            drag.target: itemRoot
            drag.axis: Drag.XAxis
            drag.minimumX: 0
            drag.maximumX: container.width - width
            drag.threshold: 8

            onPositionChanged: {
                if (drag.active) {
                    checkAndSwap();
                }
            }

            onReleased: (mouse) => {
                if (drag.active) {
                    itemRoot.x = Qt.binding(function() { return getActualX(itemKey); });
                } else {
                    triggerClick(mouse);
                }
            }

            onCanceled: {
                itemRoot.x = Qt.binding(function() { return getActualX(itemKey); });
            }

            function triggerClick(mouse) {
                if (mouse.button === Qt.RightButton) {
                    if (itemKey === "notifications") {
                        Preferences.notificationMode = (Preferences.notificationMode === 1) ? 0 : 1;
                    } else if (itemKey === "volume") {
                        Volume.toggleMute();
                    }
                } else {
                    if (itemKey === "wifi") {
                        PopoutService.toggleNetworkPopout();
                    } else if (itemKey === "bluetooth") {
                        PopoutService.toggleBluetoothPopout();
                    } else if (itemKey === "volume") {
                        PopoutService.toggleAudioPopout();
                    } else if (itemKey === "notifications") {
                        PopoutService.toggleNotificationPopout();
                    }
                }
            }
        }

        function checkAndSwap() {
            let activeWidth = getItemWidth(itemKey);
            let centerX = itemRoot.x + activeWidth / 2;
            let currentIdx = visibleKeys.indexOf(itemKey);
            if (currentIdx === -1) return;

            let closestIdx = currentIdx;
            let minDistance = 999999;

            for (let i = 0; i < visibleKeys.length; i++) {
                let k = visibleKeys[i];
                let centerI = getTargetX(k) + getItemWidth(k) / 2;
                let dist = Math.abs(centerX - centerI);
                if (dist < minDistance) {
                    minDistance = dist;
                    closestIdx = i;
                }
            }

            if (closestIdx !== currentIdx) {
                let activeKey = visibleKeys[currentIdx];
                let targetKey = visibleKeys[closestIdx];

                let fullIdx1 = Preferences.indicatorsOrder.indexOf(activeKey);
                let fullIdx2 = Preferences.indicatorsOrder.indexOf(targetKey);

                if (fullIdx1 !== -1 && fullIdx2 !== -1) {
                    let order = [...Preferences.indicatorsOrder];
                    let temp = order[fullIdx1];
                    order[fullIdx1] = order[fullIdx2];
                    order[fullIdx2] = temp;

                    Preferences.indicatorsOrder = order;
                }
            }
        }
    }

    Component {
        id: wifiComponent
        Item {
            implicitWidth: root.itemWidth
            height: parent ? parent.height : Theme.dimensions.barItemHeight

            BaseIcon {
                anchors.centerIn: parent
                icon: "wifi"
                size: Theme.dimensions.iconBase
                color: parent.containsMouse ? Theme.colors.primary : Theme.colors.text
            }
        }
    }

    Component {
        id: bluetoothComponent
        Item {
            implicitWidth: root.itemWidth
            height: parent ? parent.height : Theme.dimensions.barItemHeight

            BaseIcon {
                anchors.centerIn: parent
                icon: Bluetooth.powered ? "bluetooth" : "bluetooth_disabled"
                size: Theme.dimensions.iconBase
                color: parent.containsMouse ? Theme.colors.primary : Theme.colors.text
            }
        }
    }

    Component {
        id: notificationsComponent
        Item {
            implicitWidth: root.itemWidth
            height: parent ? parent.height : Theme.dimensions.barItemHeight

            readonly property bool dndActive: Preferences.notificationMode === 1
            readonly property bool hasUnread: PopoutService.notificationManager ? PopoutService.notificationManager.unreadCount > 0 : false

            BaseIcon {
                anchors.centerIn: parent
                icon: {
                    if (parent.dndActive)
                        return "notifications_off";

                    if (parent.hasUnread)
                        return "notifications_unread";

                    return "notifications";
                }
                size: Theme.dimensions.iconBase
                color: parent.containsMouse ? Theme.colors.primary : (parent.dndActive ? Theme.colors.error : Theme.colors.text)
            }
        }
    }

    Component {
        id: trayComponent
        Item {
            anchors.fill: parent

            RowLayout {
                anchors.fill: parent
                spacing: Theme.geometry.spacing.small

                // Custom expand / collapse button
                BaseButton {
                    id: expandButton
                    implicitWidth: 32
                    implicitHeight: 32
                    customRadius: Theme.geometry.radius
                    hoverEnabled: true

                    onClicked: {
                        Preferences.indicatorsTrayExpanded = !Preferences.indicatorsTrayExpanded;
                    }

                    BaseIcon {
                        anchors.centerIn: parent
                        icon: Preferences.indicatorsTrayExpanded ? "last_page" : "first_page"
                        size: Theme.dimensions.iconBase + 4
                        weight: Theme.typography.weights.bold
                        color: expandButton.containsMouse ? Theme.colors.primary : Theme.colors.text
                    }
                }

                // Row containing actual tray icons
                RowLayout {
                    id: trayLayout
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: Theme.geometry.spacing.small
                    clip: true
                    opacity: Preferences.indicatorsTrayExpanded ? 1.0 : 0.0

                    Behavior on opacity {
                        NumberAnimation {
                            duration: Theme.animations.normal
                        }
                    }

                    Repeater {
                        model: SystemTray.items.values
                        delegate: Item {
                            id: delegateRoot
                            readonly property var trayData: modelData

                            implicitWidth: Theme.dimensions.iconBase
                            implicitHeight: Theme.dimensions.iconBase

                            Image {
                                id: trayIcon
                                anchors.fill: parent
                                source: {
                                    if (!trayData) return "";
                                    var resolved = LauncherService.resolveIcon(trayData.id);
                                    if (resolved) return resolved;
                                    return LauncherService.resolveIcon(trayData.icon) || "";
                                }
                                sourceSize: Qt.size(48, 48)
                                fillMode: Image.PreserveAspectFit
                                smooth: true
                                asynchronous: true

                                layer.enabled: true
                                layer.effect: MultiEffect {
                                    colorization: 1.0
                                    colorizationColor: trayMouseArea.containsMouse ? Theme.colors.primary : Theme.colors.text

                                    Behavior on colorizationColor {
                                        ColorAnimation {
                                            duration: Theme.animations.fast
                                        }
                                    }
                                }
                            }

                            MouseArea {
                                id: trayMouseArea
                                anchors.fill: parent
                                acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: (mouse) => {
                                    if (!trayData) return;
                                    if (mouse.button === Qt.LeftButton) {
                                        trayData.activate();
                                    } else if (mouse.button === Qt.RightButton) {
                                        if (trayData.menu) {
                                            TrayService.closeCurrentMenu();
                                            PopoutService.closeAll();
                                            if (trayMenuComponent.status === Component.Ready) {
                                                var iconGlobalPos = trayIcon.mapToItem(null, 0, 0);
                                                var barWidth = root.barWindow ? root.barWindow.width : 0;
                                                var screen = Quickshell.screens[0];
                                                var barScreenX = 0;
                                                if (root.barWindow) {
                                                    if (Preferences.barFitToContent)
                                                        barScreenX = (screen.width - barWidth) / 2;
                                                    else
                                                        barScreenX = Preferences.barMarginSide;
                                                }
                                                var menu = trayMenuComponent.createObject(root, {
                                                    "trayItem": trayData,
                                                    "anchorX": barScreenX + iconGlobalPos.x + (trayIcon.width / 2),
                                                    "anchorMinX": barScreenX,
                                                    "anchorMaxX": barScreenX + barWidth
                                                });
                                                if (menu) {
                                                    menu.open();
                                                    TrayService.openMenu(menu, trayData, Qt.point(iconGlobalPos.x, iconGlobalPos.y));
                                                }
                                            }
                                        }
                                    } else if (mouse.button === Qt.MiddleButton) {
                                        trayData.secondaryActivate();
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    Component {
        id: volumeComponent
        Item {
            id: volItemRoot
            readonly property bool containsMouse: parent ? parent.containsMouse : false
            implicitWidth: root.itemWidth
            height: parent ? parent.height : Theme.dimensions.barItemHeight

            // Wheel scrolls volume
            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.NoButton
                onWheel: (wheel) => {
                    let delta = wheel.angleDelta.y > 0 ? 0.05 : -0.05;
                    Volume.setVolume(Math.max(0, Math.min(1, Volume.volume + delta)));
                }
            }

            // Volume icon — fades out on hover
            BaseIcon {
                anchors.centerIn: parent
                icon: Volume.volumeIcon
                size: Theme.dimensions.iconBase
                color: Theme.colors.text
                opacity: volItemRoot.containsMouse ? 0.0 : 1.0
                Behavior on opacity { BaseAnimation { duration: Theme.animations.fast } }
            }

            // Percentage value — fades in on hover
            BaseText {
                anchors.centerIn: parent
                anchors.verticalCenterOffset: 1
                text: Volume.muted ? "M" : Math.round(Volume.volume * 100).toString()
                pixelSize: Theme.typography.size.large
                weight: Theme.typography.weights.bold
                color: Theme.colors.primary
                horizontalAlignment: Text.AlignHCenter
                opacity: volItemRoot.containsMouse ? 1.0 : 0.0
                Behavior on opacity { BaseAnimation { duration: Theme.animations.fast } }
            }
        }
    }
}
