import QtQuick
import QtQuick.Layouts
import qs

Item {
    id: root

    implicitHeight: Math.max(root.itemHeight, layout.implicitHeight)
    implicitWidth: layout.implicitWidth

    property string title: ""
    property int titleSize: Globals.typography.size.large
    property string titleFamily: Globals.typography.family
    property string subtitle: ""
    property int subtitleSize: Globals.typography.size.medium
    property bool showSubtitleOnHover: false
    property bool bounceTitleOnHover: false
    // Row metrics live here rather than in Globals: only this component sizes
    // list rows, so they're tuned in one place. Both stay writable because
    // Menu.qml overrides them per-instance.
    property int itemHeight: 44 * Globals.shellScale
    property int leftIconBoxSize: root.itemHeight
    
    property string leftIcon: ""
    property bool leftIconInteractive: true
    property bool leftIconActive: false
    property real leftIconScale: 1.0
    
    property bool showVerticalSeparator: false
    
    property string rightIcon: "chevron-right"
    property bool rightIconVisible: true
    
    property bool selected: false

    // ── KEYBOARD NAVIGATION CONTRACT ───────────────────────────────────
    // Set navigable: false on rows that should be skipped by SettingsNav.
    property bool navigable: true
    property bool navHighlighted: false

    function activate() {
        root.clicked();
        return true;
    }

    // Internal indicator (the gradient bar on the left edge).
    // Set to false when an external BaseIndicator is used instead (e.g. for hover-driven indicators).
    property bool showInternalIndicator: true

    readonly property bool containsMouse: mainMouseArea.containsMouse
    readonly property bool hovered: containsMouse
    // Highlight when either the pointer is over the row or keyboard nav is on it.
    readonly property bool highlighted: root.navHighlighted || root.containsMouse
    readonly property bool _subtitleCollapsed: root.showSubtitleOnHover && !root.highlighted

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
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }

    RowLayout {
        id: layout
        anchors.fill: parent
        spacing: Globals.geometry.spacing.medium

        Rectangle {
            visible: root.showInternalIndicator && root.selected
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
            Layout.leftMargin: root.showVerticalSeparator ? 8 : 0
            spacing: 0

            BaseText {
                id: titleText
                visible: root.title !== ""
                text: root.title
                pixelSize: root.titleSize
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
                Layout.preferredHeight: root._subtitleCollapsed ? 0 : subtitleText.implicitHeight
                Layout.topMargin: root._subtitleCollapsed ? 0 : Math.max(0, root.itemHeight - titleText.implicitHeight - subtitleText.implicitHeight)
                Behavior on Layout.preferredHeight { BaseMotion { easing.type: Easing.OutQuart } }
                Behavior on Layout.topMargin { BaseMotion { easing.type: Easing.OutQuart } }
                clip: true
                opacity: root._subtitleCollapsed ? 0.0 : 1.0
                Behavior on opacity { BaseMotion { } }

                BaseText {
                    id: subtitleText
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right
                    text: root.subtitle
                    pixelSize: root.subtitleSize
                    muted: true
                    elide: Text.ElideRight
                    maximumLineCount: 1
                    horizontalAlignment: Text.AlignLeft
                }
            }
        }

        BaseIcon {
            visible: root.rightIconVisible && root.rightIcon !== ""
            icon: root.rightIcon
            color: root.selected ? Globals.colors.primary : (root.highlighted ? Globals.colors.text : Globals.colors.muted)
            Behavior on color { BaseMotion { } }
            Layout.alignment: Qt.AlignVCenter
        }
    }
}
