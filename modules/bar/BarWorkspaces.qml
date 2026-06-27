import "../../../components"
import QtQuick
import QtQuick.Layouts
import Quickshell
import qs

Item {
    id: root


    // Compositor.workspaces already builds a 1..workspaceCount slot list;
    // it now also reacts to Preferences.bar.workspaceCountChanged via Compositor.qml.
    readonly property var workspaces: Compositor.workspaces || []
    readonly property int activeWorkspaceId: localActiveId !== -1 ? localActiveId : Compositor.activeWorkspaceId
    property int localActiveId: -1
    property Item activeItem: null
    property Item hoveredItem: null

    // Instantly sync local state when the compositor's event arrives
    Connections {
        target: Compositor
        function onActiveWorkspaceIdChanged() {
            if (Compositor.activeWorkspaceId === localActiveId) {
                localActiveId = -1;
            }
        }
    }

    // Timer to reset local state if the event never arrives (safety fallback)
    Timer {
        id: syncTimer
        interval: 1000
        onTriggered: localActiveId = -1
    }

    Layout.fillWidth: false
    // Ensure standard bar height and vertical alignment
    implicitHeight: Theme.dimensions.barItemHeight
    implicitWidth: layout.implicitWidth

    RowLayout {
        id: layout

        anchors.fill: parent
        spacing: 8

        Repeater {
            model: root.workspaces

            Item {
                id: indicator

                // Primary: match by ID from service. Fallback: use ws.focused flag from
                // the workspace data itself, in case the service chain hasn't delivered yet.
                readonly property bool isActive: modelData.id === root.activeWorkspaceId
                    || (root.activeWorkspaceId === -1 && modelData.isFocused)
                readonly property bool hasWindows: modelData.hasWindows

                // Determine target width: 28 for active pill, 8 for all other slots
                // Empty workspaces are shown at low opacity so the configured count is visible
                readonly property real targetWidth: isActive ? 28 : 8

                implicitHeight: Theme.dimensions.barItemHeight
                implicitWidth: targetWidth

                // Update the active item reference
                Component.onCompleted: if (isActive) root.activeItem = indicator
                onIsActiveChanged: if (isActive) root.activeItem = indicator

                visible: true
                opacity: isActive ? 1.0 : (mouseArea.containsMouse ? 1.0 : (hasWindows ? 0.6 : 0.2))

                Behavior on implicitWidth {
                    BaseAnimation { }
                }
                Behavior on opacity {
                    BaseAnimation { }
                }

                MouseArea {
                    id: mouseArea

                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    onClicked: (mouse) => {
                        if (mouse.button === Qt.RightButton) {
                            IslandService.toggleSettings("Workspaces");
                        } else {
                            root.localActiveId = modelData.id;
                            syncTimer.restart();
                            Compositor.switchToWorkspace(modelData.idx || modelData.id);
                        }
                    }

                    onContainsMouseChanged: {
                        if (containsMouse) {
                            root.hoveredItem = indicator;
                        } else if (root.hoveredItem === indicator) {
                            root.hoveredItem = null;
                        }
                    }
                }

                Rectangle {
                    anchors.centerIn: parent
                    width: parent.implicitWidth
                    height: 8
                    radius: height / 2

                    // Gradient fills the rounded shape — no clipping needed
                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop { id: gs1; position: 0.0; color: Theme.colors.text }
                        GradientStop { id: gs2; position: 1.0; color: Theme.colors.text }
                    }

                    // Left stop: primary → secondary → primary (loops)
                    SequentialAnimation {
                        id: wave1
                        loops: Animation.Infinite
                        running: indicator.isActive
                        // Snap to start colour so each loop begins correctly
                        ColorAnimation { target: gs1; property: "color"; to: Theme.colors.primary; duration: 0 }
                        ColorAnimation { target: gs1; property: "color"; to: Theme.colors.secondary; duration: 2000; easing.type: Easing.InOutSine }
                        ColorAnimation { target: gs1; property: "color"; to: Theme.colors.primary; duration: 2000; easing.type: Easing.InOutSine }
                        onRunningChanged: if (!running) fadeGs1.start()
                    }

                    // Right stop: secondary → primary → secondary (opposite phase)
                    SequentialAnimation {
                        id: wave2
                        loops: Animation.Infinite
                        running: indicator.isActive
                        ColorAnimation { target: gs2; property: "color"; to: Theme.colors.secondary; duration: 0 }
                        ColorAnimation { target: gs2; property: "color"; to: Theme.colors.primary; duration: 2000; easing.type: Easing.InOutSine }
                        ColorAnimation { target: gs2; property: "color"; to: Theme.colors.secondary; duration: 2000; easing.type: Easing.InOutSine }
                        onRunningChanged: if (!running) fadeGs2.start()
                    }

                    // Fade back to solid text colour when deactivated
                    ColorAnimation { id: fadeGs1; target: gs1; property: "color"; to: Theme.colors.text; duration: Theme.animations.fast }
                    ColorAnimation { id: fadeGs2; target: gs2; property: "color"; to: Theme.colors.text; duration: Theme.animations.fast }
                }
            }
        }
    }

}
