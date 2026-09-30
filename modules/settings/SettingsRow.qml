import QtQuick
import QtQuick.Layouts
import qs

Item {
    id: root

    property string icon: ""
    property string label: ""
    property string description: ""
    property bool showSeparator: true
    property bool clickable: false

    default property alias content: controlContainer.data

    readonly property bool hovered: clickArea.containsMouse
    readonly property real contentCenterY: contentWrapper.y + contentWrapper.height / 2

    // ── KEYBOARD NAVIGATION CONTRACT ───────────────────────────────────
    // A row is navigable when it is visible and has something to do: either it
    // is clickable (a nav row to a subpage) or it hosts an adjustable control.
    readonly property bool focusable: visible && height > 0 && (clickable || control !== null)
    property bool navFocused: false

    // The first child in the default content slot, treated as this row's
    // control when it understands one of the adjust/activate shapes below.
    readonly property Item control: {
        for (var i = 0; i < controlContainer.children.length; i++) {
            var c = controlContainer.children[i];
            if (c !== rightSpacer)
                return c;
        }
        return null;
    }

    // Step the control by delta (Left/Right). Returns true if it consumed the
    // input. Duck-typed so each Base* control can be driven without coupling.
    function adjust(delta) {
        var c = root.control;
        if (!c) return false;

        // BaseSegmentedControl: step currentValue through its model and emit.
        if (c.activated !== undefined && c.model !== undefined && c.currentValue !== undefined) {
            var n = c.model.length;
            if (n <= 0) return false;
            var cur = -1;
            for (var i = 0; i < n; i++) {
                var v = (c.valueRole !== undefined && c.model[i] && c.model[i][c.valueRole] !== undefined)
                    ? c.model[i][c.valueRole] : c.model[i];
                if (v === c.currentValue) { cur = i; break; }
            }
            if (cur < 0) cur = 0;
            var next = Math.max(0, Math.min(n - 1, cur + (delta < 0 ? -1 : 1)));
            if (next === cur) return true;
            var nv = (c.valueRole !== undefined && c.model[next] && c.model[next][c.valueRole] !== undefined)
                ? c.model[next][c.valueRole] : c.model[next];
            c.currentValue = nv;
            c.activated(next, nv);
            return true;
        }

        if (typeof c.incrementCurrentIndex === "function" && c.model !== undefined) {
            // ComboBox.
            if (delta < 0) c.currentIndex = Math.max(0, c.currentIndex - 1);
            else c.currentIndex = Math.min(c.count - 1, c.currentIndex + 1);
            return true;
        }
        if (typeof c.increase === "function" && typeof c.decrease === "function") {
            // SpinBox / Slider, both expose increase()/decrease().
            if (delta < 0) c.decrease();
            else c.increase();
            return true;
        }
        return false;
    }

    // Enter/Space on the row: toggles a switch, or fires the row click.
    function activate() {
        var c = root.control;
        if (c && c.checked !== undefined) {
            // Prefer toggle() so a control that emits toggled (e.g. BaseSwitch)
            // reaches onToggled call sites; fall back to a checked assignment.
            if (typeof c.toggle === "function")
                c.toggle();
            else
                c.checked = !c.checked;
            return true;
        }
        if (root.clickable) {
            root.clicked();
            return true;
        }
        return false;
    }

    signal clicked()

    implicitHeight: Math.max(layout.implicitHeight, Globals.dimensions.settingsRowHeight) + Globals.geometry.spacing.large * 2 + 1
    Layout.fillWidth: true

    MouseArea {
        id: clickArea
        anchors.fill: parent
        enabled: root.clickable
        hoverEnabled: root.clickable
        cursorShape: root.clickable ? Qt.PointingHandCursor : Qt.ArrowCursor
        z: -1
        onClicked: root.clicked()
    }

    Item {
        id: contentWrapper
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.leftMargin: Globals.geometry.spacing.medium
        anchors.rightMargin: Globals.geometry.spacing.medium
        height: Math.max(layout.implicitHeight, Globals.dimensions.settingsRowHeight)

        RowLayout {
            id: layout
            anchors.fill: parent
            spacing: Globals.geometry.spacing.medium

            BaseIcon {
                visible: root.icon !== ""
                icon: root.icon
                Layout.alignment: Qt.AlignVCenter
            }

            ColumnLayout {
                Layout.preferredWidth: parent.width * 0.4
                Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
                spacing: 2

                BaseText {
                    text: root.label
                    pixelSize: Globals.typography.size.large
                    weight: Globals.typography.weights.medium
                }
                BaseText {
                    visible: root.description !== ""
                    text: root.description
                    pixelSize: Globals.typography.size.small
                    muted: true
                }
            }

            RowLayout {
                id: controlContainer
                Layout.preferredWidth: parent.width * 0.6
                Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                spacing: Globals.geometry.spacing.small

                property bool hasFillWidthChild: {
                    for (var i = 0; i < children.length; i++) {
                        var child = children[i];
                        if (child === rightSpacer) continue;
                        if (child.Layout && child.Layout.fillWidth) return true;
                    }
                    return false;
                }

                Item {
                    id: rightSpacer
                    Layout.fillWidth: !controlContainer.hasFillWidthChild
                    visible: !controlContainer.hasFillWidthChild
                }
            }
        }
    }

    BaseSeparator {
        visible: root.showSeparator
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: root.icon !== "" ? (Globals.geometry.spacing.medium + Globals.dimensions.iconMedium + Globals.geometry.spacing.medium) : Globals.geometry.spacing.medium
    }
}
