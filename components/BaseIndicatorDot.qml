import QtQuick
import qs

BaseIndicator {
    width: 4
    height: 4

    Rectangle {
        anchors.fill: parent
        radius: width / 2
        color: Theme.colors.primary
    }
}
