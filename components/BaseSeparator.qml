import qs
import QtQuick
import QtQuick.Layouts
import ".."

Rectangle {
    id: root

    enum Orientation {
        Horizontal,
        Vertical
    }

    property int orientation: BaseSeparator.Horizontal

    implicitWidth: orientation === BaseSeparator.Vertical
        ? Globals.geometry.borderWidth.hair
        : 20 * Globals.shellScale
    implicitHeight: orientation === BaseSeparator.Horizontal
        ? Globals.geometry.borderWidth.hair
        : 20 * Globals.shellScale

    Layout.fillWidth: orientation === BaseSeparator.Horizontal
    Layout.fillHeight: orientation === BaseSeparator.Vertical

    color: Globals.colors.border
    opacity: 0.5
}
