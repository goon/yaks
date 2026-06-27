import QtQuick
import QtQuick.Controls
import qs

SpinBox {
    id: root

    property string suffix: ""

    Item {
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: 120
        
        HoverHandler {
            id: hoverArea
        }
    }

    readonly property bool expanded: root.hovered || root.activeFocus || hoverArea.hovered


    editable: true
    leftPadding: expanded ? 32 : 0
    rightPadding: expanded ? 32 : 0
    topPadding: 0
    bottomPadding: 0

    Behavior on implicitWidth { BaseAnimation { } }

    background: Item {
        implicitWidth: root.expanded ? 120 : 0
        implicitHeight: 36
    }

    contentItem: Item {
        implicitWidth: textInput.implicitWidth + (suffixText.visible ? suffixText.implicitWidth + 4 : 0)
        implicitHeight: Math.max(textInput.implicitHeight, 36)
        property alias text: textInput.text

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.IBeamCursor
            onClicked: textInput.forceActiveFocus()
        }

        DragHandler {
            target: null
            cursorShape: Qt.SizeHorCursor
            property int startValue: 0

            onActiveChanged: {
                if (active) {
                    startValue = root.value
                    textInput.focus = false
                }
            }

            onTranslationChanged: {
                if (active) {
                    let steps = Math.round(translation.x / 4)
                    root.value = startValue + (steps * root.stepSize)
                }
            }
        }

        TextInput {
            id: textInput
            x: root.expanded ? (parent.width - width) / 2 : 0
            y: (parent.height - height) / 2
            
            text: root.textFromValue(root.value, root.locale)
            color: Globals.colors.text
            font.pixelSize: Globals.typography.size.medium
            font.family: Globals.typography.family
            horizontalAlignment: Qt.AlignHCenter
            verticalAlignment: Qt.AlignVCenter
            readOnly: !root.editable
            validator: root.validator
            inputMethodHints: Qt.ImhDigitsOnly
            leftPadding: 0
            rightPadding: 0
            topPadding: 0
            bottomPadding: 0
        }

        BaseText {
            id: suffixText
            x: textInput.x + textInput.width + 4
            y: textInput.y + (textInput.height - height) / 2 + 1 // +1 for baseline adjustment
            text: root.suffix
            visible: root.suffix !== ""
            pixelSize: Globals.typography.size.small
            color: Globals.colors.muted
        }
    }

    up.indicator: BaseIcon {
        x: root.width - width - 8
        y: (root.height - height) / 2
        icon: "add"
        color: root.up.pressed ? Globals.colors.primary : Globals.colors.text
        opacity: root.expanded ? 1.0 : 0.0
        Behavior on opacity { BaseAnimation { } }
    }

    down.indicator: BaseIcon {
        x: 8
        y: (root.height - height) / 2
        icon: "remove"
        color: root.down.pressed ? Globals.colors.primary : Globals.colors.text
        opacity: root.expanded ? 1.0 : 0.0
        Behavior on opacity { BaseAnimation { } }
    }
}
