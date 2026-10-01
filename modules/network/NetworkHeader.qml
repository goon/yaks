import QtQuick
import QtQuick.Layouts
import qs

// The header strip both device popouts (wifi, bluetooth) open with: a scan
// button that spins while a scan runs, a power switch, a rule, and an empty
// state. Only the labels and the callbacks differ between them, so those are
// the whole API — everything else is shared so the two cannot drift apart.
Item {
    id: root

    required property bool enabled
    required property bool scanning
    property int spinMs: 1000

    signal scanClicked()
    signal toggleClicked()

    implicitHeight: headerRow.implicitHeight + Globals.geometry.spacing.xs

    RowLayout {
        id: headerRow
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        spacing: Globals.geometry.spacing.xs

        BaseButton {
            id: refreshButton
            icon: "refresh-cw"
            width: Globals.dimensions.controlHeightSmall
            height: Globals.dimensions.controlHeightSmall
            hoverEnabled: false
            onClicked: root.scanClicked()

            NumberAnimation {
                target: refreshButton
                property: "iconRotation"
                from: 0; to: 360
                duration: root.spinMs
                loops: Animation.Infinite
                running: root.scanning
            }
        }

        BaseSwitch {
            checked: root.enabled
            onClicked: root.toggleClicked()
        }
    }

    BaseSeparator {
        anchors.bottom: parent.bottom
        width: parent.width
        visible: root.enabled
    }
}