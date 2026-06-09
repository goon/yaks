import QtQuick
import QtQuick.Layouts
import qs

BaseButton {
    id: root
    
    property int holdDuration: 1500
    property real holdProgress: 0.0
    property bool hoverBackgroundEnabled: true
    property bool holdRingEnabled: true
    
    signal holdTriggered()

    onPressedSignal: holdAnim.start()
    onReleasedSignal: {
        holdAnim.stop()
        holdProgress = 0.0
    }
    onExited: {
        holdAnim.stop()
        holdProgress = 0.0
    }
    
    NumberAnimation {
        id: holdAnim
        target: root
        property: "holdProgress"
        from: 0.0
        to: 1.0
        duration: root.holdDuration
        onFinished: {
            if (root.holdProgress >= 1.0) {
                root.holdProgress = 0.0
                root.holdTriggered()
            }
        }
    }

    hoverColor: Theme.colors.transparent

    // Breathing Traffic Light Background
    Rectangle {
        anchors.fill: parent
        radius: root.customRadius > 0 ? root.customRadius : Theme.geometry.radius
        color: root.iconColor
        visible: root.containsMouse && root.hoverBackgroundEnabled
        opacity: 0.1

        SequentialAnimation on opacity {
            loops: Animation.Infinite
            running: root.containsMouse
            NumberAnimation { to: 0.3; duration: 1000; easing.type: Easing.InOutSine }
            NumberAnimation { to: 0.1; duration: 1000; easing.type: Easing.InOutSine }
        }
    }

        // Dynamic Gradient Border around the box
    Canvas {
        id: ringCanvas
        anchors.fill: parent
        visible: root.holdProgress > 0.0 && root.holdRingEnabled
        
        onPaint: {
            var ctx = getContext("2d");
            ctx.clearRect(0, 0, width, height);
            
            if (root.holdProgress <= 0.0) return;
            
            var lineWidth = 2.5;
            // Get radius, matching the button's background
            var rawRadius = root.customRadius > 0 ? root.customRadius : Theme.geometry.radius;
            var r = Math.max(0, rawRadius - lineWidth / 2);
            
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
            var d = totalLength * root.holdProgress;
            
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
            grad.addColorStop(0.0, Theme.colors.primary);
            grad.addColorStop(1.0, Theme.colors.secondary);
            
            ctx.strokeStyle = grad;
            ctx.lineWidth = lineWidth;
            ctx.lineCap = "round";
            ctx.stroke();
        }
        
        Connections {
            target: root
            function onHoldProgressChanged() { ringCanvas.requestPaint(); }
        }
    }
}
