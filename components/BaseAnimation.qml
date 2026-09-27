import QtQuick
import qs

/**
 * BaseAnimation - Standardized Animation Hub for the shell
 * Can be used as a simple PropertyAnimation.
 */
SequentialAnimation {
    id: root
    
    property alias target: anim.target
    property alias targets: anim.targets
    property alias property: anim.property
    property alias to: anim.to
    property alias from: anim.from
    property alias easing: anim.easing
    
    property int delay: 0
    property int duration: -1
    
    readonly property int _dur: {
        var base = (duration !== -1) ? duration : Globals.animations.normal;
        return Math.max(0, Math.round(base / Preferences.animations.speedMultiplier));
    }

    PauseAnimation {
        duration: Math.max(0, Math.round(root.delay / Preferences.animations.speedMultiplier))
    }

    PropertyAnimation {
        id: anim
        duration: root._dur
        easing.type: Globals.animations.easingType
        easing.bezierCurve: Globals.animations.bezierCurve
    }
}
