import QtQuick
import QtQuick.Layouts
import Quickshell
import qs

RowLayout {
    id: root

    property string title: ""
    property string icon: ""
    property color iconColor: Theme.colors.primary
    property Component headerItem: null

    visible: title !== "" || icon !== ""
    spacing: Theme.geometry.spacing.small
    Layout.fillWidth: true

    BaseIcon {
        visible: root.icon !== ""
        icon: root.icon
        color: root.iconColor
        size: Theme.geometry.spacing.medium + 2
    }

    BaseText {
        text: root.title
        weight: Theme.typography.weights.bold
        pixelSize: Theme.typography.size.large
        Layout.fillWidth: true
    }

    Loader {
        id: customHeaderItemLoader
        visible: root.headerItem !== null
        sourceComponent: root.headerItem
        Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
    }
}
