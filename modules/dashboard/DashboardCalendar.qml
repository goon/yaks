import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs

BaseBento {
    id: cal
    implicitWidth: Globals.dimensions.calendarBlockWidth + (paddingHorizontal * 2)
    implicitHeight: 320
    hoverEnabled: true

    Column {
        id: contentColumn
        Layout.fillWidth: true
        Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
        spacing: Globals.geometry.spacing.medium

            // Month navigation header
            Item {
                id: navHeader

                width: parent.width
                height: 60

                BaseButton {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    width: Globals.dimensions.calendarCellSize
                    height: parent.height
                    icon: "chevron_left"
                    scale: pressed ? 0.92 : (containsMouse ? 1.05 : 1.0)
                    clickRotate: true
                    onClicked: {
                        gridContainer.triggerSlide(-1);
                    }
                }

                // Centered overlapping text
                Item {
                    id: headerContainer
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: parent.width - (Globals.dimensions.calendarCellSize * 2)
                    height: parent.height
                    scale: headerMouseArea.pressed ? 0.98 : 1.0

                    Behavior on scale { BaseAnimation { } }

                    MouseArea {
                        id: headerMouseArea
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            var now = new Date();
                            var currentVal = Calendar.displayYear * 12 + Calendar.displayMonth;
                            var targetVal = now.getFullYear() * 12 + now.getMonth();

                            if (currentVal !== targetVal) {
                                var dir = (targetVal > currentVal) ? 1 : -1;
                                gridContainer.triggerSlide(dir, true);
                            }
                        }
                    }

                    BaseText {
                        id: monthLabel
                        anchors.centerIn: parent
                        weight: Globals.typography.weights.bold
                        pixelSize: Globals.typography.size.display * 0.6 // Approximate for 28px
                        font.letterSpacing: 2.0
                        text: Calendar.monthNames[Calendar.displayMonth].toUpperCase()

                        transform: Translate { id: monthTranslate }
                    }
                }

                BaseButton {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    width: Globals.dimensions.calendarCellSize
                    height: parent.height
                    icon: "chevron_right"
                    scale: pressed ? 0.92 : (containsMouse ? 1.05 : 1.0)
                    clickRotate: true
                    onClicked: {
                        gridContainer.triggerSlide(1);
                    }
                }
            }

            // Day headers (Sun, Mon, Tue, etc.)
            Row {
                id: dayHeaders

                width: parent.width
                spacing: Globals.geometry.spacing.small

                Repeater {
                    model: ["Su", "Mo", "Tu", "We", "Th", "Fr", "Sa"]

                    Item {
                        width: (parent.width - (6 * Globals.geometry.spacing.small)) / 7
                        implicitHeight: headerText.implicitHeight + Globals.geometry.spacing.small
                        height: implicitHeight

                        BaseText {
                            id: headerText

                            anchors.centerIn: parent
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            color: new Date().getDay() === index ? Globals.colors.primary : Globals.colors.muted
                            text: modelData
                        }
                    }
                }
            }

            Item {
                id: gridContainer
                width: parent.width
                implicitHeight: grid.height
                clip: true

                property int _animDirection: 0
                property bool _isResetting: false
                
                function triggerSlide(dir, reset) {
                    _animDirection = dir;
                    _isResetting = !!reset;
                    slideAnim.restart();
                }

                SequentialAnimation {
                    id: slideAnim
                    ParallelAnimation {
                        BaseAnimation {
                            targets: [gridTranslate]
                            property: "x"
                            from: 0
                            to: -gridContainer._animDirection * 30
                            easing.type: Easing.OutCubic
                        }
                        BaseAnimation {
                            targets: [grid, monthLabel]
                            property: "opacity"
                            to: 0
                        }
                        BaseAnimation {
                            target: monthLabel
                            property: "scale"
                            to: 0.7
                        }
                    }

                    ScriptAction { 
                        script: {
                            if (gridContainer._isResetting) 
                                Calendar.resetToCurrentMonth();
                            else 
                                Calendar.changeMonth(gridContainer._animDirection);
                        }
                    }
                    PropertyAction { targets: [gridTranslate]; property: "x"; value: gridContainer._animDirection * 30 }
                    
                    ParallelAnimation {
                        BaseAnimation {
                            targets: [gridTranslate]
                            to: 0
                            property: "x"
                            easing.type: Easing.OutBack
                        }
                        BaseAnimation {
                            targets: [grid, monthLabel]
                            property: "opacity"
                            to: 1
                        }
                        BaseAnimation {
                            target: monthLabel
                            property: "scale"
                            to: 1.0
                        }
                    }
                }

                Grid {
                    id: grid

                    width: parent.width
                    columns: 7
                    spacing: Globals.geometry.spacing.small
                    
                    transform: Translate { id: gridTranslate }

                    Repeater {
                        model: Calendar.calendarDays

                        Item {
                            id: dayButton
                            required property var modelData

                            width: (parent.width - (6 * Globals.geometry.spacing.small)) / 7
                            implicitHeight: dayText.implicitHeight + Globals.geometry.spacing.medium
                            height: implicitHeight

                            scale: dayMouseArea.pressed ? 0.95 : 1.0

                            Behavior on scale {
                                BaseAnimation {
                                }
                            }

                            BaseActiveBackground {
                                anchors.fill: parent
                                radius: Globals.geometry.radius
                                premiumActive: modelData.isToday
                                premiumHover: true
                                hoverEnabled: true
                                hovered: dayMouseArea.containsMouse
                            }

                            BaseText {
                                id: dayText

                                anchors.centerIn: parent
                                color: {
                                    if (!modelData.isCurrentMonth) return Globals.colors.muted;
                                    return Globals.colors.text;
                                }
                                pixelSize: Globals.typography.size.medium - 1
                                weight: modelData.isToday ? Globals.typography.weights.bold : Globals.typography.weights.normal
                                text: modelData.day < 10 ? "0" + modelData.day : modelData.day
                            }

                            MouseArea {
                                id: dayMouseArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.ArrowCursor
                                enabled: modelData.isCurrentMonth
                            }
                        }
                    }
                }
            }
        }
    }
