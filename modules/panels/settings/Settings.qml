import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs.services
import qs

BasePopoutWindow {
    id: root
    
    panelNamespace: "quickshell:settings"
    fixedWidth: 832
    floating: false
    openScaleFrom: 0.05
    closeScaleTo: 0.05


    body: Item {
        id: mainContainer
        implicitWidth: root.fixedWidth
        
        readonly property real maxHeight: (root.popupWindow && root.popupWindow.screen) 
            ? Math.min(900, root.popupWindow.screen.height * 0.9)
            : 800

        implicitHeight: Math.max(500, Math.min(maxHeight, mainLayout.implicitHeight))

        property string selectedPage: "About"
        property alias pageStack: pageStack

        function changePage(pageName) {
            selectedPage = pageName;
            pageStack.replace("pages/" + pageName + ".qml");
        }

        Connections {
            target: root
            function onClosed() {
                mainContainer.changePage("About");
            }
        }


        // MAIN LAYOUT
        RowLayout {
            id: mainLayout
            anchors.fill: parent
            spacing: Theme.geometry.spacing.large

            // 1. LEFT SIDEBAR
            BaseBlock {
                id: sidebar
                Layout.preferredWidth: 220
                Layout.fillWidth: false
                Layout.fillHeight: true
                padding: Theme.geometry.spacing.medium
                backgroundColor: Theme.alpha(Theme.colors.background, Theme.blur.backgroundOpacity)
                borderEnabled: true
                borderColor: Theme.colors.divider

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Theme.geometry.spacing.medium
                    Layout.bottomMargin: Theme.geometry.spacing.medium

                    // Avatar Container
                    Item {
                        id: avatarWrapper
                        width: 64
                        height: 64

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
                                duration: 12000
                                loops: Animation.Infinite
                                running: true
                            }
                        }

                        // Mask Item
                        Rectangle {
                            id: avatarMask
                            width: 54
                            height: 54
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
                            width: 54
                            height: 54
                            radius: 27
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
                                size: 26
                                color: Theme.colors.primary
                                visible: Preferences.customAvatar.toString() === "" && !avatarMouseArea.containsMouse
                            }

                            BaseIcon {
                                id: editOverlayIcon
                                anchors.centerIn: parent
                                icon: "edit"
                                size: 22
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

                    // User Info
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 1

                        BaseText {
                            text: SystemInfo.username || "User"
                            weight: Theme.typography.weights.bold
                            pixelSize: 17
                            color: Theme.colors.textLighter
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }

                        BaseText {
                            text: SystemInfo.hostname || "hostname"
                            weight: Theme.typography.weights.normal
                            pixelSize: 13
                            color: Theme.colors.muted
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }
                    }
                }

                BaseSeparator {
                    Layout.fillWidth: true
                    Layout.bottomMargin: Theme.geometry.spacing.medium
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: Theme.geometry.spacing.small

                    Repeater {
                        model: [
                            { text: "About",      icon: "info",             page: "About"                  },
                            { label: "— Shell"                                                             },
                            { text: "Shell",      icon: "dashboard",        page: "Shell",      indent: true },
                            { text: "Globals",    icon: "settings_suggest", page: "Globals",    indent: true },
                            { text: "Workspaces", icon: "grid_view",        page: "Workspaces", indent: true },
                            { text: "Bar",        icon: "border_top",       page: "Bar",        indent: true },
                            { text: "Launcher",   icon: "rocket_launch",    page: "Launcher",   indent: true },
                            { text: "Wallpaper",  icon: "image",            page: "Wallpaper",  indent: true },
                            { label: "— System"                                                            },
                            { text: "System",     icon: "settings",         page: "System",     indent: true },
                            { text: "Wi-Fi",      icon: "wifi",             page: "Wifi",       indent: true },
                            { text: "Bluetooth",  icon: "bluetooth",        page: "Bluetooth",  indent: true }
                        ]

                        delegate: ColumnLayout {
                            spacing: 0
                            Layout.fillWidth: true

                            // Section label header
                            RowLayout {
                                visible: modelData.label !== undefined
                                Layout.fillWidth: true
                                Layout.topMargin: Theme.geometry.spacing.medium
                                Layout.leftMargin: Theme.geometry.spacing.small
                                Layout.bottomMargin: 2
                                spacing: 4

                                // Gradient em dash via gradient-masked rectangle
                                Item {
                                    implicitWidth:  dashSource.implicitWidth
                                    implicitHeight: dashSource.implicitHeight

                                    // Hidden source text for the mask
                                    Text {
                                        id: dashSource
                                        text: "—"
                                        font.pixelSize: Theme.typography.size.base
                                        font.weight: Font.Bold
                                        font.family: Preferences.shellFont || "Inter"
                                        color: "white"
                                        visible: false
                                        layer.enabled: true
                                    }

                                    // Gradient rectangle masked to the text shape
                                    Rectangle {
                                        anchors.fill: dashSource
                                        gradient: Gradient {
                                            orientation: Gradient.Horizontal
                                            GradientStop { position: 0.0; color: Theme.colors.primary }
                                            GradientStop { position: 1.0; color: Theme.colors.secondary }
                                        }
                                        layer.enabled: true
                                        layer.effect: MultiEffect {
                                            maskEnabled: true
                                            maskSource: dashSource
                                        }
                                    }
                                }

                                // Section name
                                BaseText {
                                    text: (modelData.label || "").replace(/^— /, "")
                                    color: Theme.colors.muted
                                    pixelSize: Theme.typography.size.base
                                    weight: Theme.typography.weights.bold
                                }
                            }

                            // Nav button (normal or indented child)
                            BaseButton {
                                visible: modelData.label === undefined && !modelData.separator
                                Layout.fillWidth: true
                                Layout.leftMargin: modelData.indent ? Theme.geometry.spacing.medium : 0
                                text: modelData.text || ""
                                icon: modelData.icon || ""
                                selected: modelData.page === mainContainer.selectedPage
                                gradient: true
                                hoverGradient: true
                                contentAlignment: Qt.AlignLeft
                                normalColor: Theme.colors.transparent
                                textSize: modelData.indent
                                    ? Theme.typography.size.base
                                    : Theme.typography.size.medium
                                iconSize: modelData.indent
                                    ? Theme.dimensions.iconBase
                                    : Theme.dimensions.iconMedium

                                onClicked: {
                                    mainContainer.changePage(modelData.page);
                                }
                            }


                        }
                    }

                    Item {
                        Layout.fillHeight: true
                    }
                }
            }

            // 2. CONTENT AREA
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
                implicitHeight: centeredContainer.implicitHeight

                // Mask for rounded clipping
                Rectangle {
                    id: contentMask
                    anchors.fill: parent
                    radius: Theme.geometry.radius
                    color: "white"
                    visible: false
                    layer.enabled: true
                }

                // Clipped container
                Item {
                    anchors.fill: parent
                    layer.enabled: true
                    layer.effect: MultiEffect {
                        maskEnabled: true
                        maskSource: contentMask
                    }

                    BaseScroller {
                        id: contentScroller
                        anchors.fill: parent
                        clip: false

                        ColumnLayout {
                            id: centeredContainer
                            width: parent.width
                            spacing: 0

                            StackView {
                                id: pageStack
                                Layout.fillWidth: true
                                implicitHeight: currentItem ? currentItem.implicitHeight : 0
                                initialItem: "pages/About.qml"

                                replaceEnter: Transition {
                                    ParallelAnimation {
                                        BaseAnimation { property: "opacity"; from: 0; to: 1; speed: "normal"; easing.type: Easing.OutQuad }
                                        BaseAnimation { property: "scale"; from: 0.98; to: 1; speed: "normal"; easing.type: Easing.OutQuad }
                                    }
                                }

                                replaceExit: Transition {
                                    BaseAnimation { property: "opacity"; from: 1; to: 0; speed: "normal"; easing.type: Easing.OutQuad }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
