import QtQuick
import QtQuick.Layouts
import Quickshell
import qs

// The island's default face — what the capsule shows when nothing else is
// open. It measures and hosts the four bar components; it draws nothing itself
// and it is never loaded or evicted, unlike every registry module. Lives here,
// beside the components it names, so the bare filenames in resolveComponentSource
// resolve against this folder.
Item {
    id: bar

    // The capsule inset, owned by Capsule and passed in so the bar lines up
    // with every other module without reaching into Globals for it.
    required property real capsulePad

    implicitHeight: Preferences.bar.height
    implicitWidth: (contentLayout.implicitWidth || 0) + (capsulePad * 2)

    readonly property real horizontalSpacing: Globals.geometry.spacing.lg

    function resolveComponentSource(name) {
        const map = {
            "workspaces": Qt.resolvedUrl("BarWorkspaces.qml"),
            "clock": Qt.resolvedUrl("BarClock.qml"),
            "dock": Qt.resolvedUrl("BarDock.qml"),
            "indicators": Qt.resolvedUrl("BarIndicators.qml"),
        };
        return map[name] || "";
    }

    RowLayout {
        id: contentLayout

        anchors.verticalCenter: parent.verticalCenter
        anchors.horizontalCenter: parent.horizontalCenter
        height: implicitHeight
        width: mainContent.implicitWidth
        spacing: horizontalSpacing

        RowLayout {
            id: mainContent
            Layout.alignment: Qt.AlignCenter | Qt.AlignVCenter
            spacing: horizontalSpacing

            Repeater {
                model: Preferences.bar.components

                RowLayout {
                    id: componentLayout
                    Layout.alignment: Qt.AlignVCenter

                    readonly property bool isComponentVisible: (Preferences.bar.componentsEnabled[modelData] === true)
                        && (modelData === "dock" ? Compositor.hasDockWindows : bar.resolveComponentSource(modelData) !== "")
                    visible: isComponentVisible
                    spacing: horizontalSpacing

                    BaseSeparator {
                        visible: {
                            if (!componentLayout.isComponentVisible) return false;

                            for (let i = 0; i < index; i++) {
                                let otherData = Preferences.bar.components[i];
                                let otherVisible = (Preferences.bar.componentsEnabled[otherData] === true)
                                                   && (otherData === "dock" ? Compositor.hasDockWindows : bar.resolveComponentSource(otherData) !== "");
                                if (otherVisible) return true;
                            }
                            return false;
                        }
                        orientation: BaseSeparator.Vertical
                        Layout.fillHeight: false
                        Layout.preferredHeight: 22
                        Layout.preferredWidth: 1
                        Layout.alignment: Qt.AlignVCenter
                    }

                    Loader {
                        Layout.alignment: Qt.AlignVCenter
                        source: bar.resolveComponentSource(modelData)
                    }
                }
            }
        }
    }
}
