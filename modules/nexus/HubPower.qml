import QtQuick
import QtQuick.Layouts
import qs

Item {
    id: root
    implicitHeight: 72
    implicitWidth: layout.implicitWidth

    property real activeHoldProgress: Math.max(btnShutdown.holdProgress, btnRestart.holdProgress, btnSleep.holdProgress, btnLogout.holdProgress)
    property color activeActionColor: {
        if (btnShutdown.holdProgress > 0) return btnShutdown.actionColor;
        if (btnRestart.holdProgress > 0) return btnRestart.actionColor;
        if (btnSleep.holdProgress > 0) return btnSleep.actionColor;
        if (btnLogout.holdProgress > 0) return btnLogout.actionColor;
        return Theme.colors.primary;
    }

    component PowerButton: BaseButtonHold {
        id: btn

        Layout.fillWidth: true
        Layout.fillHeight: true
        customRadius: 0
        normalColor: Theme.colors.transparent
        hoverEnabled: false
        hoverGradient: false
        hoverBackgroundEnabled: false
        holdRingEnabled: false
        icon: ""

        property string actionIcon: ""
        property string actionLabel: ""
        property color actionColor: Theme.colors.text

        property real breathScale: 1.0
        SequentialAnimation {
            loops: Animation.Infinite
            running: btn.containsMouse
            onStopped: btn.breathScale = 1.0

            NumberAnimation {
                target: btn; property: "breathScale"
                to: 1.1; duration: 900; easing.type: Easing.InOutSine
            }
            NumberAnimation {
                target: btn; property: "breathScale"
                to: 1.0; duration: 900; easing.type: Easing.InOutSine
            }
        }

        property real bubbleAlpha: 0.18
        SequentialAnimation {
            loops: Animation.Infinite
            running: btn.containsMouse
            onStopped: btn.bubbleAlpha = 0.18

            NumberAnimation {
                target: btn; property: "bubbleAlpha"
                to: 0.38; duration: 800; easing.type: Easing.InOutSine
            }
            NumberAnimation {
                target: btn; property: "bubbleAlpha"
                to: 0.18; duration: 800; easing.type: Easing.InOutSine
            }
        }

        ColumnLayout {
            anchors.centerIn: parent
            spacing: Theme.geometry.spacing.small

            Item {
                Layout.alignment: Qt.AlignHCenter
                width: 48
                height: 48

                Canvas {
                    id: ringCanvas
                    anchors.fill: parent
                    opacity: btn.containsMouse ? 1.0 : 0.0

                    Behavior on opacity {
                        NumberAnimation { duration: Theme.animations.fast }
                    }

                    property int cornerRadius: Theme.geometry.radius
                    onCornerRadiusChanged: requestPaint()

                    onPaint: {
                        var ctx = getContext("2d");
                        ctx.clearRect(0, 0, width, height);
                        var lw = 1.5;
                        var bw = 36, bh = 36;
                        var bx = (width - bw) / 2;
                        var by = (height - bh) / 2;
                        var r = Math.min(Theme.geometry.radius, bw / 2, bh / 2);
                        ctx.beginPath();
                        ctx.moveTo(bx + r, by);
                        ctx.lineTo(bx + bw - r, by);
                        ctx.arcTo(bx + bw, by, bx + bw, by + r, r);
                        ctx.lineTo(bx + bw, by + bh - r);
                        ctx.arcTo(bx + bw, by + bh, bx + bw - r, by + bh, r);
                        ctx.lineTo(bx + r, by + bh);
                        ctx.arcTo(bx, by + bh, bx, by + bh - r, r);
                        ctx.lineTo(bx, by + r);
                        ctx.arcTo(bx, by, bx + r, by, r);
                        ctx.closePath();
                        var grad = ctx.createLinearGradient(0, 0, width, height);
                        grad.addColorStop(0.0, btn.actionColor);
                        grad.addColorStop(1.0, Theme.colors.secondary);
                        ctx.strokeStyle = grad;
                        ctx.lineWidth = lw;
                        ctx.stroke();
                    }

                    Connections {
                        target: btn
                        function onContainsMouseChanged() { ringCanvas.requestPaint(); }
                    }
                }

                Rectangle {
                    width: 36; height: 36
                    radius: Theme.geometry.radius
                    anchors.centerIn: parent
                    scale: btn.breathScale
                    color: Theme.alpha(btn.actionColor, btn.bubbleAlpha)

                    Behavior on scale { NumberAnimation { duration: Theme.animations.fast } }

                    BaseIcon {
                        anchors.centerIn: parent
                        icon: btn.actionIcon
                        size: Theme.dimensions.iconBase
                        color: btn.actionColor
                    }
                }
            }
        }
    }

    Rectangle {
        anchors.fill: parent
        color: Theme.alpha(Theme.colors.surface, Theme.opacity.surface)
        radius: Theme.geometry.radius * 1.5
        clip: true

        RowLayout {
            id: layout
            anchors.fill: parent
            spacing: 0

            PowerButton {
                id: btnShutdown
                actionIcon: "power_settings_new"
                actionLabel: "Shutdown"
                actionColor: Theme.colors.error
                onHoldTriggered: { IslandService.closeAll(); Power.shutdown(); }
            }

            Rectangle {
                width: 1; Layout.fillHeight: true
                Layout.topMargin: Theme.geometry.spacing.large
                Layout.bottomMargin: Theme.geometry.spacing.large
                color: Theme.alpha(Theme.colors.border, 0.6)
            }

            PowerButton {
                id: btnRestart
                actionIcon: "restart_alt"
                actionLabel: "Restart"
                actionColor: Theme.colors.primary
                onHoldTriggered: { IslandService.closeAll(); Power.reboot(); }
            }

            Rectangle {
                width: 1; Layout.fillHeight: true
                Layout.topMargin: Theme.geometry.spacing.large
                Layout.bottomMargin: Theme.geometry.spacing.large
                color: Theme.alpha(Theme.colors.border, 0.6)
            }

            PowerButton {
                id: btnSleep
                actionIcon: "bedtime"
                actionLabel: "Sleep"
                actionColor: Theme.colors.info
                onHoldTriggered: { IslandService.closeAll(); Power.suspend(); }
            }

            Rectangle {
                width: 1; Layout.fillHeight: true
                Layout.topMargin: Theme.geometry.spacing.large
                Layout.bottomMargin: Theme.geometry.spacing.large
                color: Theme.alpha(Theme.colors.border, 0.6)
            }

            PowerButton {
                id: btnLogout
                actionIcon: "logout"
                actionLabel: "Logout"
                actionColor: Theme.colors.secondary
                onHoldTriggered: { IslandService.closeAll(); Power.logout(); }
            }
        }
    }

    Canvas {
        id: globalRingCanvas
        anchors.fill: parent
        visible: root.activeHoldProgress > 0.0
        
        property int globalRadius: Theme.geometry.radius * 1.5
        onGlobalRadiusChanged: requestPaint()

        onPaint: {
            var ctx = getContext("2d");
            ctx.clearRect(0, 0, width, height);
            
            if (root.activeHoldProgress <= 0.0) return;
            
            var lineWidth = 2.5;
            var r = Math.max(0, globalRadius - lineWidth / 2);
            
            var w = width - lineWidth;
            var h = height - lineWidth;
            var x = lineWidth / 2;
            var y = lineWidth / 2;
            
            var segments = [
                { len: (w - 2*r)/2, draw: function(ctx, p) { ctx.lineTo(x + w/2 + p, y); } },
                { len: Math.PI/2 * r, draw: function(ctx, p) { 
                    var angle = -Math.PI/2 + (p / (Math.PI/2 * r)) * (Math.PI/2);
                    ctx.arc(x + w - r, y + r, r, -Math.PI/2, angle, false);
                }},
                { len: h - 2*r, draw: function(ctx, p) { ctx.lineTo(x + w, y + r + p); } },
                { len: Math.PI/2 * r, draw: function(ctx, p) { 
                    var angle = 0 + (p / (Math.PI/2 * r)) * (Math.PI/2);
                    ctx.arc(x + w - r, y + h - r, r, 0, angle, false);
                }},
                { len: w - 2*r, draw: function(ctx, p) { ctx.lineTo(x + w - r - p, y + h); } },
                { len: Math.PI/2 * r, draw: function(ctx, p) { 
                    var angle = Math.PI/2 + (p / (Math.PI/2 * r)) * (Math.PI/2);
                    ctx.arc(x + r, y + h - r, r, Math.PI/2, angle, false);
                }},
                { len: h - 2*r, draw: function(ctx, p) { ctx.lineTo(x, y + h - r - p); } },
                { len: Math.PI/2 * r, draw: function(ctx, p) { 
                    var angle = Math.PI + (p / (Math.PI/2 * r)) * (Math.PI/2);
                    ctx.arc(x + r, y + r, r, Math.PI, angle, false);
                }},
                { len: (w - 2*r)/2, draw: function(ctx, p) { ctx.lineTo(x + r + p, y); } }
            ];
            
            var totalLength = 2*(w - 2*r) + 2*(h - 2*r) + 2*Math.PI*r;
            var d = totalLength * root.activeHoldProgress;
            
            ctx.beginPath();
            ctx.moveTo(x + w/2, y); // Start at top center
            
            for (var i = 0; i < segments.length; i++) {
                if (d <= 0) break;
                var seg = segments[i];
                if (d >= seg.len) {
                    seg.draw(ctx, seg.len);
                    d -= seg.len;
                } else {
                    seg.draw(ctx, d);
                    d = 0;
                }
            }
            
            var grad = ctx.createLinearGradient(0, 0, width, height);
            grad.addColorStop(0.0, root.activeActionColor);
            grad.addColorStop(1.0, Theme.colors.secondary);
            
            ctx.strokeStyle = grad;
            ctx.lineWidth = lineWidth;
            ctx.lineCap = "round";
            ctx.stroke();
        }
        
        Connections {
            target: root
            function onActiveHoldProgressChanged() { globalRingCanvas.requestPaint(); }
        }
    }
}
