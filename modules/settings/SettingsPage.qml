import QtQuick
import QtQuick.Controls
import qs
BaseContainer {
    id: root
    width: parent ? parent.width : 0
    spacing: 0

    onRightClicked: {
        if (root.StackView.view && root.StackView.view.depth > 1) {
            root.StackView.view.pop(null);
        }
    }
}
