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

    component PowerButton: BaseButton {
        buttonMode: "hold"
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



        ColumnLayout {
            anchors.centerIn: parent
            spacing: Theme.geometry.spacing.small

            BaseButton {
            buttonMode: "action"
                Layout.alignment: Qt.AlignHCenter
                icon: btn.actionIcon
                actionColor: btn.actionColor
                inactiveColor: btn.actionColor
                hovered: btn.containsMouse
                interactive: false
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
