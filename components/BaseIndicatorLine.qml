import QtQuick
import qs

BaseIndicator {
    width: 3
    height: 20

    Rectangle {
        anchors.fill: parent
        radius: width / 2
        gradient: Gradient {
            orientation: Gradient.Vertical
            GradientStop { position: 0.0; color: Theme.colors.primary }
            GradientStop { position: 1.0; color: Theme.colors.secondary }
        }
    }
}
