import ".."
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Notifications
import qs

BaseContainer {
    id: root

    property var notification: null

    readonly property bool isScreenshot: {
        if (!root.notification) return false;
        const sum = (root.notification.summary || "").toLowerCase();
        return sum.indexOf("screenshot") !== -1;
    }

    readonly property bool isRecording: {
        if (!root.notification) return false;
        const sum = (root.notification.summary || "").toLowerCase();
        return sum.indexOf("recording") !== -1;
    }

    clickable: true
    Layout.fillWidth: true
    implicitWidth: 350

    RowLayout {
        Layout.fillWidth: true
        spacing: Globals.geometry.spacing.md
        Layout.alignment: Qt.AlignTop

                Rectangle {
                    Layout.preferredWidth: Globals.dimensions.thumbnail
                    Layout.preferredHeight: Layout.preferredWidth
                    Layout.alignment: Qt.AlignTop

                    color: "transparent"
                    radius: 0

                    function resolveSource(src) {
                        return Launcher.resolveIcon(src);
                    }

                    // 1. Specific Image (Highest Priority)
                    // e.g. User Avatar, Album Art
                    Image {
                        id: specificImage
                        anchors.centerIn: parent
                        width: Math.min(Globals.dimensions.thumbnail, parent.width - 4)
                        height: width

                        source: parent.resolveSource(root.notification ? root.notification.image : "")
                        sourceSize.width: width
                        sourceSize.height: height
                        visible: !root.isScreenshot && !root.isRecording && status === Image.Ready && source.toString() !== ""
                    }

                    // 2. App Icon (Middle Priority)
                    // e.g. Discord Logo, Spotify Logo
                    // Visible if Specific Image is missing or failed to load
                    Image {
                        id: appIconImage
                        anchors.centerIn: parent
                        width: Math.min(Globals.dimensions.thumbnail, parent.width - 4)
                        height: width

                        source: parent.resolveSource(root.notification ? root.notification.appIcon : "")
                        sourceSize.width: width
                        sourceSize.height: height
                        visible: !root.isScreenshot && !root.isRecording && !specificImage.visible && status === Image.Ready && source.toString() !== ""
                    }

                    // 3. Icon Symbol (Custom Fallback)
                    // Visible if appIcon or image starts with 'symbol:'
                    Rectangle {
                        anchors.centerIn: parent
                        width: 36
                        height: 36
                        radius: Globals.geometry.radius
                        color: Globals.colors.tint
                        visible: symbolIcon.icon !== ""
                        z: 10

                        BaseIcon {
                            id: symbolIcon
                            anchors.centerIn: parent
                            size: Globals.typography.icon.md
                            icon: {
                                if (!root.notification) return "";
                                if (root.isScreenshot) return "image";
                                if (root.isRecording) return "monitor-play";
                                const ai = root.notification.appIcon || "";
                                const img = root.notification.image || "";

                                function extract(s) {
                                    if (s.startsWith("symbol:")) return s.substring(7);
                                    const idx = s.indexOf("symbol:");
                                    if (idx !== -1) return s.substring(idx + 7);
                                    return "";
                                }

                                const res = extract(ai);
                                if (res) return res;
                                return extract(img);
                            }
                            color: Globals.colors.primary
                        }
                    }

                    // 4. Icon Fallback (Lowest Priority)
                    // Visible if NO images or symbols are loaded
                    BaseIcon {
                        anchors.centerIn: parent
                        visible: !specificImage.visible && !appIconImage.visible && !symbolIcon.visible
                        icon: "bell-dot"
                        width: size
                        height: size
                        color: Globals.colors.primary
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                    spacing: Globals.geometry.spacing.xs

                    BaseText {
                        Layout.fillWidth: false
                        pixelSize: Globals.typography.size.lg
                        weight: Globals.typography.weight.demi
                        text: root.notification ? (root.notification.summary || "") : ""
                        maximumLineCount: 1
                        elide: Text.ElideRight
                        // Allow the summary to shrink but avoid circular dependency on parent.width
                        Layout.maximumWidth: root.width - 120
                    }
                }

            }

            BaseText {
                Layout.fillWidth: true
                Layout.preferredWidth: 200 // Hint to help Layout
                text: root.notification ? (root.notification.body || "") : ""
                wrapMode: Text.Wrap
                maximumLineCount: 2
                elide: Text.ElideRight
                visible: text !== ""
            }
}
