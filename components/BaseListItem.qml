import QtQuick
import QtQuick.Layouts
import qs

Item {
    id: root

    // Row metrics live here rather than in Globals: this is the one row both the
    // settings pages and the list menus use, so it owns its own height.
    property int itemHeight: 36 * Globals.shellScale
    property int leftIconBoxSize: Globals.dimensions.iconMedium
    property int verticalPadding: Globals.geometry.spacing.large
    property real controlWidthRatio: 0.6

    implicitHeight: Math.max(root.itemHeight, layout.implicitHeight) + root.verticalPadding * 2
    implicitWidth: layout.implicitWidth
    Layout.fillWidth: true

    property string title: ""
    property string titleFamily: Globals.typography.family
    property string subtitle: ""
    property bool bounceTitleOnHover: false

    property string leftIcon: ""
    property bool leftIconInteractive: false
    property bool leftIconActive: false
    property real leftIconScale: 1.0

    property bool showVerticalSeparator: false

    // Children dropped into a row land in the right-hand control slot.
    default property alias content: controlRow.data

    // A row that hosts a control reads as a settings row: it keeps side
    // padding, caps its label column so the control keeps its share, and draws
    // a rule underneath. List rows (icon + title + chevron) do none of it.
    readonly property bool settingsStyle: control !== null
    property bool showSeparator: true

    // The first child in the control slot, treated as this row's control.
    // Non-Items (a Font.qml Timer, say) land here too, so skip them.
    readonly property Item control: {
        for (var i = 0; i < controlRow.children.length; i++) {
            var c = controlRow.children[i];
            if (c !== rightSpacer && c instanceof Item)
                return c;
        }
        return null;
    }

    property string rightIcon: "chevron-right"
    property bool rightIconVisible: true

    property bool selected: false
    property bool clickable: false

    // ── KEYBOARD NAVIGATION CONTRACT ───────────────────────────────────
    // A row is navigable when it is visible and has something to do: either it
    // is clickable (a nav row to a subpage) or it hosts an adjustable control.
    // SettingsNav owns the keyboard; the row only advertises itself.
    readonly property bool navigable: visible && height > 0 && (root.clickable || control !== null)
    property bool navHighlighted: false

    readonly property bool containsMouse: root.clickable && mainMouseArea.containsMouse
    readonly property bool hovered: containsMouse
    // Highlight when either the pointer is over the row or keyboard nav is on it.
    readonly property bool highlighted: root.clickable && (root.navHighlighted || root.containsMouse)

    // Drive the bounce/pulse from the shared highlight so keyboard navigation
    // animates the row exactly like hover does.
    onHighlightedChanged: {
        if (root.bounceTitleOnHover && root.highlighted) {
            titleText.opacity = 1.0;
            titleText.scale = 1.0;
            titleBounce.restart();
        } else {
            titleBounce.stop();
            titleText.scale = 1.0;
            titleText.opacity = 1.0;
        }
    }

    signal clicked()
    signal leftIconClicked()

    MouseArea {
        id: mainMouseArea
        anchors.fill: parent
        enabled: root.clickable
        hoverEnabled: root.clickable
        cursorShape: root.clickable ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: root.clicked()
    }

    RowLayout {
        id: layout
        anchors.fill: parent
        spacing: Globals.geometry.spacing.medium
        Layout.leftMargin: root.settingsStyle ? Globals.geometry.spacing.medium : 0
        Layout.rightMargin: root.settingsStyle ? Globals.geometry.spacing.medium : 0

        Rectangle {
            visible: root.selected
            Layout.preferredWidth: 3
            Layout.preferredHeight: 20
            Layout.alignment: Qt.AlignVCenter
            radius: width / 2
            gradient: Gradient {
                orientation: Gradient.Vertical
                GradientStop { position: 0.0; color: Globals.colors.primary }
                GradientStop { position: 1.0; color: Globals.colors.secondary }
            }
        }

        Item {
            visible: root.leftIcon !== ""
            Layout.preferredWidth: root.leftIconBoxSize
            Layout.preferredHeight: root.leftIconBoxSize
            Layout.alignment: Qt.AlignVCenter
            scale: root.leftIconScale

            BaseButton {
                visible: root.leftIconInteractive
                anchors.centerIn: parent
                icon: root.leftIcon
                size: Globals.dimensions.iconMedium
                iconColor: root.leftIconActive ? Globals.colors.primary : Globals.colors.text
                onClicked: root.leftIconClicked()
                z: 2 // Sit above the main MouseArea
            }

            BaseIcon {
                visible: !root.leftIconInteractive
                anchors.centerIn: parent
                icon: root.leftIcon
                size: Globals.dimensions.iconMedium
                color: root.selected ? Globals.colors.primary : (root.highlighted ? Globals.colors.primary : Globals.colors.text)
                Behavior on color { BaseMotion { } }
            }
        }

        BaseSeparator {
            visible: root.showVerticalSeparator
            orientation: BaseSeparator.Vertical
            Layout.fillHeight: true
            Layout.topMargin: Globals.geometry.spacing.medium
            Layout.bottomMargin: Globals.geometry.spacing.medium
            opacity: 0.3
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.maximumWidth: root.settingsStyle
                ? layout.width * (1 - root.controlWidthRatio)
                : Number.POSITIVE_INFINITY
            Layout.leftMargin: root.showVerticalSeparator ? Globals.geometry.spacing.medium : 0
            spacing: 0

            BaseText {
                id: titleText
                visible: root.title !== ""
                text: root.title
                pixelSize: Globals.typography.size.large
                family: root.titleFamily
                weight: root.selected ? Globals.typography.weights.bold : Globals.typography.weights.medium
                color: root.selected ? Globals.colors.primary : (root.highlighted ? Globals.colors.primary : Globals.colors.text)
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignLeft
                elide: Text.ElideRight
                maximumLineCount: 1
                transformOrigin: Item.Left

                SequentialAnimation {
                    id: titleBounce

                    NumberAnimation { target: titleText; property: "scale"; to: 1.10; duration: Globals.motion.hover; easing.type: Easing.OutQuad }
                    NumberAnimation { target: titleText; property: "scale"; to: 0.97; duration: Globals.motion.hover; easing.type: Easing.InOutQuad }
                    NumberAnimation { target: titleText; property: "scale"; to: 1.0; duration: Globals.motion.hover; easing.type: Globals.motion.easeSpring }
                }

                Behavior on color { BaseMotion { } }
            }

            Item {
                Layout.fillWidth: true
                visible: root.subtitle !== ""
                Layout.preferredHeight: subtitleText.implicitHeight
                Layout.topMargin: Math.max(0, root.itemHeight - titleText.implicitHeight - subtitleText.implicitHeight)
                clip: true

                BaseText {
                    id: subtitleText
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right
                    text: root.subtitle
                    pixelSize: Globals.typography.size.medium
                    muted: true
                    elide: Text.ElideRight
                    maximumLineCount: 1
                    horizontalAlignment: Text.AlignLeft
                }
            }
        }

        RowLayout {
            id: controlRow
            visible: root.settingsStyle
            Layout.preferredWidth: layout.width * root.controlWidthRatio
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
                Layout.fillWidth: !controlRow.hasFillWidthChild
                visible: !controlRow.hasFillWidthChild
            }
        }

        BaseIcon {
            visible: root.rightIconVisible && root.rightIcon !== "" && !root.settingsStyle
            icon: root.rightIcon
            color: root.selected ? Globals.colors.primary : (root.highlighted ? Globals.colors.text : Globals.colors.muted)
            Behavior on color { BaseMotion { } }
            Layout.alignment: Qt.AlignVCenter
        }
    }

    BaseSeparator {
        visible: root.showSeparator && root.settingsStyle
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: root.leftIcon !== ""
            ? Globals.geometry.spacing.medium + Globals.dimensions.iconMedium + Globals.geometry.spacing.medium
            : Globals.geometry.spacing.medium
    }
}
