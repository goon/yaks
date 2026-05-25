import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import qs

BaseBlock {
    id: root

    implicitWidth: 200
    implicitHeight: 160

    padding: 0
    paddingHorizontal: 0
    paddingVertical: 0

    // Single fill-item that takes up the whole contentContainer
    Item {
        Layout.fillWidth: true
        Layout.fillHeight: true

        // Inner column centered in the available space
        Column {
            anchors.centerIn: parent
            spacing: Theme.geometry.spacing.medium

            // Avatar Container
            Item {
                id: avatarWrapper
                anchors.horizontalCenter: parent.horizontalCenter
                width: 84
                height: 84

                // Gradient Ring border
                Canvas {
                    id: ringCanvas
                    anchors.fill: parent
                    
                    onPaint: {
                        var ctx = getContext("2d");
                        ctx.clearRect(0, 0, width, height);

                        var lineWidth = 1.5;
                        var cx = width / 2;
                        var cy = height / 2;
                        var r = (width - lineWidth) / 2;

                        ctx.beginPath();
                        ctx.arc(cx, cy, r, 0, 2 * Math.PI);

                        var grad = ctx.createLinearGradient(0, 0, width, height);
                        grad.addColorStop(0.0, Theme.colors.primary);
                        grad.addColorStop(1.0, Theme.colors.secondary);

                        ctx.strokeStyle = grad;
                        ctx.lineWidth = lineWidth;
                        ctx.stroke();
                    }

                    onWidthChanged: requestPaint()
                    onHeightChanged: requestPaint()

                    RotationAnimation {
                        target: ringCanvas
                        property: "rotation"
                        from: 0
                        to: 360
                        duration: 12000 // 12 seconds per full rotation for a smooth, premium feel
                        loops: Animation.Infinite
                        running: true
                    }
                }

                // Mask Item (must be sibling of container with layer enabled)
                Rectangle {
                    id: avatarMask
                    width: 74
                    height: 74
                    anchors.centerIn: parent
                    radius: width / 2
                    color: "black"
                    visible: false
                    layer.enabled: true
                    layer.smooth: true
                }

                // Inner Avatar Circle
                Rectangle {
                    id: avatarContainer
                    anchors.centerIn: parent
                    width: 74
                    height: 74
                    radius: 37
                    color: Theme.alpha(Theme.colors.primary, 0.1)

                    // Enable layering and mask with MultiEffect for perfect circular clip
                    layer.enabled: true
                    layer.smooth: true
                    layer.effect: MultiEffect {
                        maskEnabled: true
                        maskSource: avatarMask
                    }

                    // User Profile Image (Preserve circular crop)
                    Image {
                        id: avatarImg
                        anchors.fill: parent
                        source: Preferences.customAvatar
                        visible: source.toString() !== ""
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        opacity: avatarMouseArea.containsMouse ? 0.4 : 1.0
                        Behavior on opacity { NumberAnimation { duration: 150 } }
                    }

                    // Fallback default icon
                    BaseIcon {
                        anchors.centerIn: parent
                        icon: "person"
                        size: 38
                        color: Theme.colors.primary
                        visible: Preferences.customAvatar.toString() === "" && !avatarMouseArea.containsMouse
                    }

                    // Edit overlay icon
                    BaseIcon {
                        id: editOverlayIcon
                        anchors.centerIn: parent
                        icon: "edit"
                        size: 32
                        color: Preferences.customAvatar.toString() !== "" ? "white" : Theme.colors.primary
                        visible: avatarMouseArea.containsMouse
                        
                        onVisibleChanged: {
                            if (visible) {
                                editIconAnim.restart();
                            }
                        }

                        SequentialAnimation {
                            id: editIconAnim
                            BaseAnimation { target: editOverlayIcon; property: "scale"; from: 1.0; to: 0.7; speed: "fast" }
                            BaseAnimation { target: editOverlayIcon; property: "scale"; to: 1.0; speed: "fast"; easing.type: Easing.OutBack }
                        }
                    }

                    // Click handler to open native GTK file dialog
                    MouseArea {
                        id: avatarMouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            var pythonCode = "import gi; gi.require_version('Gtk', '3.0'); from gi.repository import Gtk; Gtk.init(); dialog = Gtk.FileChooserDialog(title='Select Profile Image', action=Gtk.FileChooserAction.OPEN); dialog.add_buttons(Gtk.STOCK_CANCEL, Gtk.ResponseType.CANCEL, Gtk.STOCK_OPEN, Gtk.ResponseType.OK); response = dialog.run(); print(dialog.get_filename() if response == Gtk.ResponseType.OK else '', end=''); dialog.destroy()";
                            
                            var bashScript = 
                                "if python3 -c \"import gi; gi.require_version('Gtk', '3.0')\" 2>/dev/null; then " +
                                "  python3 -c \"" + pythonCode + "\"; " +
                                "elif command -v nix-shell >/dev/null 2>&1; then " +
                                "  nix-shell -p python3Packages.pygobject3 -p gtk3 -p gobject-introspection --run \"python3 -c \\\"" + pythonCode + "\\\"\"; " +
                                "elif command -v zenity >/dev/null 2>&1; then " +
                                "  zenity --file-selection --title='Select Profile Image' --file-filter='Images | *.png *.jpg *.jpeg *.gif *.webp'; " +
                                "elif command -v kdialog >/dev/null 2>&1; then " +
                                "  kdialog --getopenfilename; " +
                                "fi";

                            var cmd = ["sh", "-c", bashScript];
                            ProcessService.run(cmd, function(stdout, exitCode) {
                                if (exitCode === 0) {
                                    var filePath = stdout.trim();
                                    if (filePath !== "") {
                                        Preferences.customAvatar = "file://" + filePath;
                                    }
                                }
                            });
                        }
                    }
                }
            }

            // User Info Text
            Column {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 2

                BaseText {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: SystemInfo.username || "User"
                    weight: Theme.typography.weights.bold
                    pixelSize: 18
                    color: Theme.colors.text
                }

                BaseText {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: SystemInfo.hostname || "hostname"
                    weight: Theme.typography.weights.normal
                    pixelSize: 15
                    color: Theme.colors.muted
                }
            }
        }
    }
}
