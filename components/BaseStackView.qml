import QtQuick
import QtQuick.Controls
import qs

StackView {
    id: root

    pushEnter: Transition {
        ParallelAnimation {
            BaseAnimation { property: "opacity"; from: 0; to: 1 }
            BaseAnimation { property: "x"; from: 50; to: 0; easing.type: Easing.OutQuart }
        }
    }
    pushExit: Transition {
        ParallelAnimation {
            BaseAnimation { property: "opacity"; from: 1; to: 0 }
            BaseAnimation { property: "x"; from: 0; to: -50; easing.type: Easing.OutQuart }
        }
    }
    popEnter: Transition {
        ParallelAnimation {
            BaseAnimation { property: "opacity"; from: 0; to: 1 }
            BaseAnimation { property: "x"; from: -50; to: 0; easing.type: Easing.OutQuart }
        }
    }
    popExit: Transition {
        ParallelAnimation {
            BaseAnimation { property: "opacity"; from: 1; to: 0 }
            BaseAnimation { property: "x"; from: 0; to: 50; easing.type: Easing.OutQuart }
        }
    }
    replaceEnter: Transition {
        BaseAnimation { property: "opacity"; from: 0; to: 1 }
    }
    replaceExit: Transition {
        BaseAnimation { property: "opacity"; from: 1; to: 0 }
    }
}
