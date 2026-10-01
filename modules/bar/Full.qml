import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.services
import qs

Item {

    property var barWindow: null
    // The capsule inset, owned by Capsule and passed in so the full bar lines
    // up with every other module without reaching into Globals for it.
    required property real capsulePad

    // Explicitly define height matching the pill clock capsule height
    implicitHeight: Preferences.bar.height
    implicitWidth: (contentLayout.implicitWidth || 0) + (capsulePad * 2)

    readonly property real horizontalSpacing: Globals.geometry.spacing.lg

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
                model: barWindow ? barWindow.components : []

                RowLayout {
                    id: componentLayout
                    Layout.alignment: Qt.AlignVCenter

                    readonly property bool isComponentVisible: (Preferences.bar.componentsEnabled[modelData] === true) && (modelData === "dock" ? Compositor.hasDockWindows : (barWindow && barWindow.resolveComponentSource(modelData) !== ""))
                    visible: isComponentVisible
                    spacing: horizontalSpacing

                    BaseSeparator {
                        visible: {
                            if (!componentLayout.isComponentVisible) return false;

                            for (let i = 0; i < index; i++) {
                                let otherData = barWindow.components[i];
                                let otherVisible = (Preferences.bar.componentsEnabled[otherData] === true) &&
                                                   (otherData === "dock" ? Compositor.hasDockWindows : (barWindow && barWindow.resolveComponentSource(otherData) !== ""));
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
                        source: barWindow ? barWindow.resolveComponentSource(modelData) : ""
                    }
                }
            }
        }
    }
}
