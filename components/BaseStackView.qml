import QtQuick
import QtQuick.Controls
import qs

StackView {
    id: root

    pushEnter: Transition {
        ParallelAnimation {
            BaseAnimation { property: "opacity"; from: 0; to: 1; duration: Globals.animations.normal }
            BaseAnimation { property: "x"; from: 50; to: 0; duration: Globals.animations.normal }
        }
    }
    pushExit: Transition {
        ParallelAnimation {
            BaseAnimation { property: "opacity"; from: 1; to: 0; duration: Globals.animations.normal }
            BaseAnimation { property: "x"; from: 0; to: -50; duration: Globals.animations.normal }
        }
    }
    popEnter: Transition {
        ParallelAnimation {
            BaseAnimation { property: "opacity"; from: 0; to: 1; duration: Globals.animations.normal }
            BaseAnimation { property: "x"; from: -50; to: 0; duration: Globals.animations.normal }
        }
    }
    popExit: Transition {
        ParallelAnimation {
            BaseAnimation { property: "opacity"; from: 1; to: 0; duration: Globals.animations.normal }
            BaseAnimation { property: "x"; from: 0; to: 50; duration: Globals.animations.normal }
        }
    }
    replaceEnter: Transition {
        BaseAnimation { property: "opacity"; from: 0; to: 1; duration: Globals.animations.normal }
    }
    replaceExit: Transition {
        BaseAnimation { property: "opacity"; from: 1; to: 0; duration: Globals.animations.normal }
    }
}
