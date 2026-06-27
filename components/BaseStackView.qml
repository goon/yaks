import QtQuick
import QtQuick.Controls
import qs

StackView {
    id: root

    pushEnter: Transition {
        ParallelAnimation {
            BaseAnimation { property: "opacity"; from: 0; to: 1; duration: Theme.animations.normal }
            BaseAnimation { property: "x"; from: 50; to: 0; duration: Theme.animations.normal; easing.type: Easing.OutQuart }
        }
    }
    pushExit: Transition {
        ParallelAnimation {
            BaseAnimation { property: "opacity"; from: 1; to: 0; duration: Theme.animations.normal }
            BaseAnimation { property: "x"; from: 0; to: -50; duration: Theme.animations.normal; easing.type: Easing.OutQuart }
        }
    }
    popEnter: Transition {
        ParallelAnimation {
            BaseAnimation { property: "opacity"; from: 0; to: 1; duration: Theme.animations.normal }
            BaseAnimation { property: "x"; from: -50; to: 0; duration: Theme.animations.normal; easing.type: Easing.OutQuart }
        }
    }
    popExit: Transition {
        ParallelAnimation {
            BaseAnimation { property: "opacity"; from: 1; to: 0; duration: Theme.animations.normal }
            BaseAnimation { property: "x"; from: 0; to: 50; duration: Theme.animations.normal; easing.type: Easing.OutQuart }
        }
    }
    replaceEnter: Transition {
        ParallelAnimation {
            BaseAnimation { property: "opacity"; from: 0; to: 1; duration: Theme.animations.normal }
        }
    }
    replaceExit: Transition {
        ParallelAnimation {
            BaseAnimation { property: "opacity"; from: 1; to: 0; duration: Theme.animations.normal }
        }
    }
}
