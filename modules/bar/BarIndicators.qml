import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import qs
import qs.services

Item {
    id: root

    Layout.alignment: Qt.AlignVCenter
    Layout.fillWidth: false
    implicitWidth: background.implicitWidth
    implicitHeight: capsuleRoot.itemHeight

    readonly property int spacing: Globals.geometry.spacing.xs
    readonly property int indicatorItemWidth: 32

    // ── SINGLE SOURCE OF TRUTH ──────────────────────────────────────────

    readonly property var _indicatorModel: [
        { key: "wifi", icon: "wifi" },
        { key: "bluetooth", icon: "bluetooth" },
        { key: "notifications", icon: "bell" },
        { key: "settings", icon: "settings" },
        { key: "power", icon: "power" }
    ]

    // Saved order first, then any model key the saved order never mentions, so a
    // stale or partial order can never hide an icon. Recomputed on demand
    // rather than bound: the saved order lives behind a var property and a
    // binding on it does not reliably re-evaluate.
    property var orderedKeys: _computeOrderedKeys()

    function _computeOrderedKeys() {
        var model = _indicatorModel.map(function(m) { return m.key; });
        var keys = Preferences.indicators.order.filter(function(k) { return model.indexOf(k) !== -1; });
        model.forEach(function(k) {
            if (keys.indexOf(k) === -1) keys.push(k);
        });
        return keys;
    }

    Connections {
        target: Preferences.indicators
        function onOrderChanged() { root.orderedKeys = root._computeOrderedKeys() }
    }

    readonly property int contentWidth:
        orderedKeys.length * indicatorItemWidth + Math.max(0, orderedKeys.length - 1) * spacing

    function getActualX(key) {
        return Math.max(0, orderedKeys.indexOf(key)) * (indicatorItemWidth + spacing);
    }

    function _openModule(key) {
        switch (key) {
            case "wifi": Modules.toggleModule("wifi"); break;
            case "bluetooth": Modules.toggleModule("bluetooth"); break;
            case "notifications": Modules.toggleModule("notifications"); break;
            case "power": Modules.toggleModule("power"); break;
            case "settings": Modules.toggleSettings(); break;
        }
    }

    function _handleRightClick(key) {
        if (key === "notifications")
            Preferences.notifications.mode = Preferences.notifications.mode === 1 ? 0 : 1;
    }

    BaseContainer {
        id: background

        anchors.fill: parent
        implicitHeight: capsuleRoot.itemHeight
        hoverEnabled: false

        Item {
            id: container
            implicitWidth: root.contentWidth
            implicitHeight: capsuleRoot.itemHeight
            height: parent.height

            Repeater {
                model: root._indicatorModel

                delegate: IndicatorIcon {
                    itemKey: modelData.key
                    iconName: {
                        if (modelData.key === "notifications") {
                            if (Preferences.notifications.mode === 1) return "bell-off";
                            if (Notifications.unreadCount > 0) return "bell-dot";
                            return "bell";
                        }
                        return modelData.icon;
                    }
                }
            }
        }
    }

    component IndicatorIcon: Item {
        id: itemRoot

        required property var modelData
        required property string itemKey
        property string iconName

        height: parent.height
        width: root.indicatorItemWidth

        readonly property bool isDragging: dragArea.drag.active

        // Follow the actual coordinates when not dragged.
        // Uses a Binding element (not an inline binding) to avoid a self-referential
        // binding loop: `x: isDragging ? x : ...` would reference `x` itself and crash.
        Binding {
            target: itemRoot
            property: "x"
            value: getActualX(itemKey)
            when: !itemRoot.isDragging
            // Without RestoreNone, QML reverts x to 0 (the pre-binding default) when
            // the drag starts and the Binding releases, causing a visible flick to the
            // left edge before the drag system corrects it.
            restoreMode: Binding.RestoreNone
        }

        onIsDraggingChanged: {
            if (isDragging) {
                // Only close other modules — do NOT close the fullbar we're dragging inside
                if (Modules.activeModuleName !== "full_bar") {
                    Modules.closeAll();
                }
            }
        }
        BaseIcon {
            anchors.centerIn: parent
            icon: itemRoot.iconName
            opacity: dragArea.containsMouse ? 1.0 : 0.8
            Behavior on opacity { BaseMotion { duration: Globals.motion.hover } }

            layer.enabled: true
            layer.effect: MultiEffect {
                shadowEnabled: true
                shadowColor: dragArea.containsMouse ? Globals.colors.hover : "transparent"
                shadowBlur: 0.8
                shadowHorizontalOffset: 0
                shadowVerticalOffset: 0
                Behavior on shadowColor { ColorAnimation { duration: Globals.motion.hover } }
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
                    swapDebounce.restart();
                }
            }

            onReleased: (mouse) => {
                if (!drag.active) {
                    triggerClick(mouse);
                }
                // No need to restore x — the Binding element re-engages automatically
                // when isDragging becomes false.
            }

            onCanceled: {
                // No need to restore x — the Binding element re-engages automatically.
            }

            function triggerClick(mouse) {
                if (mouse.button === Qt.RightButton) {
                    root._handleRightClick(itemKey);
                } else {
                    root._openModule(itemKey);
                }
            }
        }

        Timer {
            id: swapDebounce
            interval: 50
            repeat: false
            onTriggered: {
                if (itemRoot.isDragging) checkAndSwap();
            }
        }

        function checkAndSwap() {
            const keys = orderedKeys.slice();
            const currentIdx = keys.indexOf(itemKey);
            if (currentIdx === -1) return;

            const centerX = itemRoot.x + indicatorItemWidth / 2;
            let closestIdx = currentIdx;
            let minDistance = Infinity;
            for (let i = 0; i < keys.length; i++) {
                const dist = Math.abs(centerX - getActualX(keys[i]) - indicatorItemWidth / 2);
                if (dist < minDistance) {
                    minDistance = dist;
                    closestIdx = i;
                }
            }
            if (closestIdx === currentIdx) return;

            // Snapshot Preferences.indicators.order to avoid reactive mid-write
            const order = Preferences.indicators.order.slice();
            const from = order.indexOf(itemKey);
            const to = order.indexOf(keys[closestIdx]);
            if (from === -1 || to === -1) return;

            // Move (shift) not swap: remove from current slot and insert at target slot.
            // All icons between the two positions shift by one — no teleporting.
            order.splice(from, 1);
            order.splice(to, 0, itemKey);
            Preferences.indicators.order = order;
        }
    }


}
