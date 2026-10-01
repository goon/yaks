import QtQuick
import QtQuick.Controls
import qs

StackView {
    id: root

    // The file name of the page on top, or "" when nothing is pushed. Pages
    // pushed through `pushPage` carry their file name as their objectName, so
    // callers can ask the stack what is showing without walking `currentItem`.
    readonly property string selectedPage: currentItem ? String(currentItem.objectName || "") : ""

    // The only supported way to push a page: tags the item with its file name
    // so callers can ask the stack what is showing, and refuses to stack the
    // page that is already on top, so repeating a navigation is a no-op rather
    // than a duplicate push.
    //
    // `url` must already be resolved by the caller (Qt.resolvedUrl) — a relative
    // URL would resolve against this file's directory instead of the calling
    // module's, which is the wrong directory for that module's pages.
    function pushPage(url, name) {
        if (root.selectedPage === name) return;
        root.push(url, { objectName: name });
    }

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
