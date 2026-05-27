import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import qs

SettingsPage {
    id: root


    padding: Theme.geometry.spacing.dynamicPadding

    ColumnLayout {
        Layout.fillWidth: true
        spacing: Theme.geometry.spacing.large

        // OS Hero Card
        BaseBlock {
            id: heroCard
            Layout.fillWidth: true
            padding: Theme.geometry.spacing.large
            premiumActive: true

            RowLayout {
                Layout.fillWidth: true
                spacing: Theme.geometry.spacing.large

                // Avatar Container
                Item {
                    id: avatarWrapper
                    Layout.preferredWidth: 150
                    Layout.preferredHeight: 150

                    // Gradient Ring border (static rounded rectangle)
                    Canvas {
                        id: ringCanvas
                        anchors.fill: parent
                        
                        onPaint: {
                            var ctx = getContext("2d");
                            ctx.clearRect(0, 0, width, height);

                            var lineWidth = 1.5;
                            var r = Theme.geometry.radius * 1.5;
                            var w = width - lineWidth;
                            var h = height - lineWidth;
                            var x = lineWidth / 2;
                            var y = lineWidth / 2;

                            ctx.beginPath();
                            ctx.moveTo(x + r, y);
                            ctx.lineTo(x + w - r, y);
                            ctx.quadraticCurveTo(x + w, y, x + w, y + r);
                            ctx.lineTo(x + w, y + h - r);
                            ctx.quadraticCurveTo(x + w, y + h, x + w - r, y + h);
                            ctx.lineTo(x + r, y + h);
                            ctx.quadraticCurveTo(x, y + h, x, y + h - r);
                            ctx.lineTo(x, y + r);
                            ctx.quadraticCurveTo(x, y, x + r, y);
                            ctx.closePath();

                            var grad = ctx.createLinearGradient(0, 0, width, height);
                            grad.addColorStop(0.0, Theme.colors.primary);
                            grad.addColorStop(1.0, Theme.colors.secondary);

                            ctx.strokeStyle = grad;
                            ctx.lineWidth = lineWidth;
                            ctx.stroke();
                        }

                        onWidthChanged: requestPaint()
                        onHeightChanged: requestPaint()
                    }

                    // Mask Item
                    Rectangle {
                        id: avatarMask
                        width: 134
                        height: 134
                        anchors.centerIn: parent
                        radius: Theme.geometry.radius * 1.2
                        color: "black"
                        visible: false
                        layer.enabled: true
                        layer.smooth: true
                    }

                    // Inner Avatar Circle
                    Rectangle {
                        id: avatarContainer
                        anchors.centerIn: parent
                        width: 134
                        height: 134
                        radius: Theme.geometry.radius * 1.2
                        color: Theme.alpha(Theme.colors.primary, 0.1)

                        layer.enabled: true
                        layer.smooth: true
                        layer.effect: MultiEffect {
                            maskEnabled: true
                            maskSource: avatarMask
                        }

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

                        BaseIcon {
                            anchors.centerIn: parent
                            icon: "person"
                            size: 68
                            color: Theme.colors.primary
                            visible: Preferences.customAvatar.toString() === "" && !avatarMouseArea.containsMouse
                        }

                        BaseIcon {
                            id: editOverlayIcon
                            anchors.centerIn: parent
                            icon: "edit"
                            size: 54
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

                // Details (OS, Kernel, Uptime)
                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: Theme.geometry.spacing.small

                    // OS
                    BaseBlock {
                        id: osBlock
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        paddingVertical: 8
                        paddingHorizontal: Theme.geometry.spacing.dynamicPadding
                        backgroundColor: Theme.alpha(Theme.colors.appBackground, 0.5)
                        clickable: true

                        RowLayout {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            spacing: Theme.geometry.spacing.medium

                            BaseIcon {
                                icon: "cloud"
                                size: Theme.dimensions.iconBase
                                color: osBlock.containsMouse ? Theme.colors.textLighter : Theme.colors.primary
                            }

                            BaseText {
                                text: "OS"
                                color: osBlock.containsMouse ? Theme.colors.textLighter : Theme.colors.text
                                pixelSize: Theme.typography.size.medium
                            }

                            Item { Layout.fillWidth: true }

                            BaseText {
                                text: SystemInfo.osName || "Unknown"
                                color: osBlock.containsMouse ? Theme.colors.textLighter : Theme.colors.text
                                pixelSize: Theme.typography.size.base
                                horizontalAlignment: Text.AlignRight
                            }
                        }
                    }

                    // Kernel
                    BaseBlock {
                        id: kernelBlock
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        paddingVertical: 8
                        paddingHorizontal: Theme.geometry.spacing.dynamicPadding
                        backgroundColor: Theme.alpha(Theme.colors.appBackground, 0.5)
                        clickable: true

                        RowLayout {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            spacing: Theme.geometry.spacing.medium

                            BaseIcon {
                                icon: "terminal"
                                size: Theme.dimensions.iconBase
                                color: kernelBlock.containsMouse ? Theme.colors.textLighter : Theme.colors.primary
                            }

                            BaseText {
                                text: "Kernel"
                                color: kernelBlock.containsMouse ? Theme.colors.textLighter : Theme.colors.text
                                pixelSize: Theme.typography.size.medium
                            }

                            Item { Layout.fillWidth: true }

                            BaseText {
                                text: (SystemInfo.kernelVersion ? SystemInfo.kernelVersion.split('-')[0] : "Unknown")
                                color: kernelBlock.containsMouse ? Theme.colors.textLighter : Theme.colors.text
                                pixelSize: Theme.typography.size.base
                                horizontalAlignment: Text.AlignRight
                            }
                        }
                    }

                    // Uptime
                    BaseBlock {
                        id: uptimeBlock
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        paddingVertical: 8
                        paddingHorizontal: Theme.geometry.spacing.dynamicPadding
                        backgroundColor: Theme.alpha(Theme.colors.appBackground, 0.5)
                        clickable: true

                        RowLayout {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            spacing: Theme.geometry.spacing.medium

                            BaseIcon {
                                icon: "schedule"
                                size: Theme.dimensions.iconBase
                                color: uptimeBlock.containsMouse ? Theme.colors.textLighter : Theme.colors.primary
                            }

                            BaseText {
                                text: "Uptime"
                                color: uptimeBlock.containsMouse ? Theme.colors.textLighter : Theme.colors.text
                                pixelSize: Theme.typography.size.medium
                            }

                            Item { Layout.fillWidth: true }

                            BaseText {
                                text: SystemInfo.uptime
                                color: uptimeBlock.containsMouse ? Theme.colors.textLighter : Theme.colors.text
                                pixelSize: Theme.typography.size.base
                                horizontalAlignment: Text.AlignRight
                            }
                        }
                    }
                }

                // NixOS Logo Block
                Rectangle {
                    id: iconBlock
                    Layout.preferredWidth: 150
                    Layout.preferredHeight: 150
                    radius: Theme.geometry.radius * 1.5
                    color: Theme.alpha(Theme.colors.background, 0.4)

                    Image {
                        id: osIcon
                        source: Qt.resolvedUrl("../../../../assets/nixos.png")
                        anchors.centerIn: parent
                        width: 96
                        height: 96
                        fillMode: Image.PreserveAspectFit
                        mipmap: true

                        RotationAnimation {
                            target: osIcon
                            from: 0
                            to: 360
                            duration: 12000 // Smooth 12s rotation
                            loops: Animation.Infinite
                            running: true
                        }
                    }
                }
            }
        }

        // Detailed Specs & Displays List
        ColumnLayout {
            Layout.fillWidth: true
            spacing: Theme.geometry.spacing.small

                // Compositor
                BaseBlock {
                    id: compositorBlock
                    Layout.fillWidth: true
                    padding: Theme.geometry.spacing.dynamicPadding
                    backgroundColor: Theme.alpha(Theme.colors.appBackground, 0.5)
                    clickable: true

                    RowLayout {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        spacing: Theme.geometry.spacing.medium

                        BaseIcon {
                            icon: "layers"
                            size: Theme.dimensions.iconBase
                            color: compositorBlock.containsMouse ? Theme.colors.textLighter : Theme.colors.primary
                        }

                        BaseText {
                            text: "Compositor"
                            color: compositorBlock.containsMouse ? Theme.colors.textLighter : Theme.colors.text
                            pixelSize: Theme.typography.size.medium
                        }

                        Item { Layout.fillWidth: true }

                        BaseText {
                            text: (SystemInfo.de !== "N/A" ? SystemInfo.de : SystemInfo.wm) || "Unknown"
                            color: compositorBlock.containsMouse ? Theme.colors.textLighter : Theme.colors.text
                            pixelSize: Theme.typography.size.base
                            horizontalAlignment: Text.AlignRight
                        }
                    }
                }

                // Memory
                BaseBlock {
                    id: memBlock
                    Layout.fillWidth: true
                    padding: Theme.geometry.spacing.dynamicPadding
                    backgroundColor: Theme.alpha(Theme.colors.appBackground, 0.5)
                    clickable: true

                    RowLayout {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        spacing: Theme.geometry.spacing.medium

                        BaseIcon {
                            icon: "memory"
                            size: Theme.dimensions.iconBase
                            color: memBlock.containsMouse ? Theme.colors.textLighter : Theme.colors.primary
                        }

                        BaseText {
                            text: "Memory"
                            color: memBlock.containsMouse ? Theme.colors.textLighter : Theme.colors.text
                            pixelSize: Theme.typography.size.medium
                        }

                        Item { Layout.fillWidth: true }

                        BaseText {
                            text: Stats.totalRam || "..."
                            color: memBlock.containsMouse ? Theme.colors.textLighter : Theme.colors.text
                            pixelSize: Theme.typography.size.base
                            horizontalAlignment: Text.AlignRight
                        }
                    }
                }

                // CPU
                BaseBlock {
                    id: cpuBlock
                    Layout.fillWidth: true
                    padding: Theme.geometry.spacing.dynamicPadding
                    backgroundColor: Theme.alpha(Theme.colors.appBackground, 0.5)
                    clickable: true

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Theme.geometry.spacing.medium

                        BaseIcon {
                            icon: "developer_board"
                            size: Theme.dimensions.iconBase
                            color: cpuBlock.containsMouse ? Theme.colors.textLighter : Theme.colors.primary
                        }

                        BaseText {
                            text: "CPU"
                            color: cpuBlock.containsMouse ? Theme.colors.textLighter : Theme.colors.text
                            pixelSize: Theme.typography.size.medium
                        }

                        Item { Layout.fillWidth: true }

                        BaseText {
                            text: SystemInfo.cpuModel || "..."
                            color: cpuBlock.containsMouse ? Theme.colors.textLighter : Theme.colors.text
                            pixelSize: Theme.typography.size.base
                            horizontalAlignment: Text.AlignRight
                            Layout.maximumWidth: 350
                            elide: Text.ElideLeft
                        }
                    }
                }

                // GPU
                BaseBlock {
                    id: gpuBlock
                    Layout.fillWidth: true
                    padding: Theme.geometry.spacing.dynamicPadding
                    backgroundColor: Theme.alpha(Theme.colors.appBackground, 0.5)
                    clickable: true

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Theme.geometry.spacing.medium

                        BaseIcon {
                            icon: "videogame_asset"
                            size: Theme.dimensions.iconBase
                            color: gpuBlock.containsMouse ? Theme.colors.textLighter : Theme.colors.primary
                        }

                        BaseText {
                            text: "GPU"
                            color: gpuBlock.containsMouse ? Theme.colors.textLighter : Theme.colors.text
                            pixelSize: Theme.typography.size.medium
                        }

                        Item { Layout.fillWidth: true }

                        BaseText {
                            text: SystemInfo.gpuModel || "..."
                            color: gpuBlock.containsMouse ? Theme.colors.textLighter : Theme.colors.text
                            pixelSize: Theme.typography.size.base
                            horizontalAlignment: Text.AlignRight
                            Layout.maximumWidth: 350
                            elide: Text.ElideLeft
                        }
                    }
                }

                // Displays
                Repeater {
                    model: Quickshell.screens

                    BaseBlock {
                        id: displayBlock
                        Layout.fillWidth: true
                        padding: Theme.geometry.spacing.dynamicPadding
                        backgroundColor: Theme.alpha(Theme.colors.appBackground, 0.5)
                        clickable: true

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: Theme.geometry.spacing.medium

                            BaseIcon {
                                icon: "desktop_windows"
                                size: Theme.dimensions.iconBase
                                color: displayBlock.containsMouse ? Theme.colors.textLighter : Theme.colors.primary
                            }

                            BaseText {
                                text: (modelData.name || "Display")
                                color: displayBlock.containsMouse ? Theme.colors.textLighter : Theme.colors.text
                                pixelSize: Theme.typography.size.medium
                            }

                            Item { Layout.fillWidth: true }

                            BaseText {
                                text: modelData.width + "x" + modelData.height
                                color: displayBlock.containsMouse ? Theme.colors.textLighter : Theme.colors.text
                                pixelSize: Theme.typography.size.base
                                horizontalAlignment: Text.AlignRight
                            }
                        }
                    }
                }
        }

    }

}
