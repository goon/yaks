import QtQuick
import qs

SequentialAnimation {
    id: root

    property alias target: motion.target
    property alias targets: motion.targets
    property alias property: motion.property
    property alias to: motion.to
    property alias from: motion.from
    property alias easing: motion.easing

    property int delay: 0
    property int duration: -1

    readonly property int _dur: (duration !== -1) ? duration : Globals.motion.standard

    PauseAnimation {
        duration: root.delay
    }

    PropertyAnimation {
        id: motion
        duration: root._dur
        easing.type: Globals.motion.easeStandard
        easing.bezierCurve: Globals.motion.easeEmphasis
    }
}
