import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs

SettingsPage {
    id: root

    title: "Time & Date"
    description: "Configure time formatting and weather location settings."

    ColumnLayout {
        Layout.fillWidth: true
        spacing: Globals.geometry.spacing.large

        SettingsGroup {
            Layout.fillWidth: true

            SettingsRow {
                icon: "schedule"
                label: "Time"

                BaseSegmentedControl {
                    Layout.fillWidth: true
                    model: [{ "label": "12 HR", "value": "12" }, { "label": "24 HR", "value": "24" }]
                    currentValue: Preferences.timedate.format
                    onActivated: (index, value) => {
                        Preferences.timedate.format = value;
                    }
                }
            }

            SettingsRow {
                icon: "location_on"
                label: "Location"
                showSeparator: false

                Item {
                    id: prefixEditor
                    Layout.fillWidth: true
                    Layout.preferredHeight: 32

                    property bool editing: false

                    RowLayout {
                        anchors.fill: parent
                        opacity: prefixEditor.editing ? 0 : 1
                        visible: opacity > 0
                        enabled: !prefixEditor.editing
                        spacing: Globals.geometry.spacing.small

                        Behavior on opacity {
                            NumberAnimation { duration: Globals.animations.fast; easing.type: Easing.OutQuart }
                        }

                        BaseText {
                            text: Preferences.weather.locationName || "Unknown Location"
                            color: Preferences.weather.locationName ? Globals.colors.text : Globals.colors.muted
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                        }

                        BaseIcon {
                            icon: "chevron_right"
                            color: Globals.colors.muted
                        }
                    }

                    BaseInput {
                        id: prefixInput
                        anchors.fill: parent
                        opacity: prefixEditor.editing ? 1 : 0
                        visible: opacity > 0
                        enabled: prefixEditor.editing

                        Behavior on opacity {
                            NumberAnimation { duration: Globals.animations.fast; easing.type: Easing.OutQuart }
                        }

                        placeholderText: "Search location..."
                        selectByMouse: true

                        onAccepted: {
                            if (text) {
                                Weather.setClosestLocation(text);
                            }
                            prefixEditor.editing = false;
                        }

                        Keys.onPressed: (event) => {
                            if (event.key === Qt.Key_Escape) {
                                prefixInput.text = "";
                                prefixEditor.editing = false;
                                event.accepted = true;
                            }
                        }

                        onActiveFocusChanged: {
                            if (!activeFocus && prefixEditor.editing) {
                                prefixEditor.editing = false;
                            }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        enabled: !prefixEditor.editing
                        onClicked: {
                            prefixInput.text = "";
                            prefixEditor.editing = true;
                            prefixInput.forceActiveFocus();
                        }
                    }
                }
            }
        }
    }
}
