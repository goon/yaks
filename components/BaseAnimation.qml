import QtQuick
import qs

/**
 * BaseAnimation - Standardized Animation Hub for the shell
 * Can be used as a simple PropertyAnimation or specialized for Springs/Staggers.
 */
SequentialAnimation {
    id: root
    
    // Compatibility properties
    property alias target: anim.target
    property alias targets: anim.targets
    property alias property: anim.property
    property alias to: anim.to
    property alias from: anim.from
    property alias easing: anim.easing
    
    // Extensions
    property int delay: 0
    property int duration: -1
    
    readonly property int _dur: {
        var base = (duration !== -1) ? duration : Theme.animations.normal;
        return Math.max(0, Math.round(base / Preferences.animations.speedMultiplier));
    }

    PauseAnimation {
        duration: Math.max(0, Math.round(root.delay / Preferences.animations.speedMultiplier))
    }

    PropertyAnimation {
        id: anim
        duration: root._dur
        easing.type: Theme.animations.easingType
        easing.bezierCurve: Theme.animations.bezierCurve
    }

    // Specialized Spring Component
    component Spring: SpringAnimation {
        property string profile: "gooey" // gooey, snappy
        
        // Physics scaling for global duration multiplier
        property real _m: Preferences.animations.speedMultiplier
        
        spring: (profile === "gooey" ? 4 : 2) * (_m * _m)
        damping: (profile === "gooey" ? 0.7 : 0.5) * _m
        mass: profile === "gooey" ? 0.8 : 1.0
    }
}
