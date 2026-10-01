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

    implicitWidth: orientation === BaseSeparator.Vertical ? 1 : 20
    implicitHeight: orientation === BaseSeparator.Horizontal ? 1 : 20

    Layout.fillWidth: orientation === BaseSeparator.Horizontal
    Layout.fillHeight: orientation === BaseSeparator.Vertical

    color: Globals.colors.border
    opacity: 0.5
}
