import QtQuick
import QtQuick.Controls
import qs
BaseContainer {
    id: root
    width: parent ? parent.width : 0
    // No padding: the capsule's `capsulePad` is the popout's inset, and a page
    // inside it adds none. Rows carry their own inset.
    spacing: 0

    onRightClicked: {
        if (root.StackView.view && root.StackView.view.depth > 1) {
            root.StackView.view.pop(null);
        }
    }
}
