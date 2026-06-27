import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import qs
import qs.services

BaseBento {
    id: root

    implicitWidth: 200
    implicitHeight: 160

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

                    BaseIcon {
                        anchors.centerIn: parent
                        icon: "person"
                        size: 38
                        color: Theme.colors.primary
                        visible: Preferences.customAvatar.toString() === "" && !avatarMouseArea.containsMouse
                    }

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
                            BaseAnimation { target: editOverlayIcon; property: "scale"; from: 1.0; to: 0.7 }
                            BaseAnimation { target: editOverlayIcon; property: "scale"; to: 1.0; easing.type: Easing.OutBack }
                        }
                    }

                    // Click handler to open native file dialog via portal
                    MouseArea {
                        id: avatarMouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Zenity.selectFile(["Images (*.png *.jpg *.jpeg *.gif *.webp)"], (path) => Preferences.customAvatar = "file://" + path)
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
                }

                BaseText {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: SystemInfo.hostname || "hostname"
                    pixelSize: 15
                    muted: true
                }
            }
        }
    }
}
