import QtQuick
import QtQuick.Controls
import qs

StackView {
    id: root

    pushEnter: Transition {
        ParallelAnimation {
            BaseMotion { property: "opacity"; from: 0; to: 1; duration: Globals.motion.standard }
            BaseMotion { property: "x"; from: 50; to: 0; duration: Globals.motion.standard }
        }
    }
    pushExit: Transition {
        ParallelAnimation {
            BaseMotion { property: "opacity"; from: 1; to: 0; duration: Globals.motion.standard }
            BaseMotion { property: "x"; from: 0; to: -50; duration: Globals.motion.standard }
        }
    }
    popEnter: Transition {
        ParallelAnimation {
            BaseMotion { property: "opacity"; from: 0; to: 1; duration: Globals.motion.standard }
            BaseMotion { property: "x"; from: -50; to: 0; duration: Globals.motion.standard }
        }
    }
    popExit: Transition {
        ParallelAnimation {
            BaseMotion { property: "opacity"; from: 1; to: 0; duration: Globals.motion.standard }
            BaseMotion { property: "x"; from: 0; to: 50; duration: Globals.motion.standard }
        }
    }
    replaceEnter: Transition {
        BaseMotion { property: "opacity"; from: 0; to: 1; duration: Globals.motion.standard }
    }
    replaceExit: Transition {
        BaseMotion { property: "opacity"; from: 1; to: 0; duration: Globals.motion.standard }
    }
}
