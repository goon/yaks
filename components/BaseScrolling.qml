import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs

Flickable {
    // No ScrollBars added - cleanest possible implementation

    id: root

    // Emulate ScrollView's availableWidth
    readonly property real availableWidth: width - leftMargin - rightMargin

    clip: true
    contentWidth: availableWidth
    contentHeight: contentItem.childrenRect.height // Auto-fit to children
    // Expose implicit height so containers can resize to fit
    implicitHeight: contentHeight
    flickableDirection: Flickable.VerticalFlick
    boundsBehavior: Flickable.StopAtBounds
}
