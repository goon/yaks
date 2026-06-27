import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs

SettingsPage {
    id: root

    title: "Launcher"
    description: "Configure search engines and launcher behaviors."

    ColumnLayout {
        Layout.fillWidth: true
        spacing: Theme.geometry.spacing.large

        SettingsGroup {
            Layout.fillWidth: true

            SettingsRow {
                icon: "search"
                label: "Search"

                BaseComboBox {
                    Layout.fillWidth: true
                    textRole: "name"
                    model: [
                        { name: "DuckDuckGo", url: "https://duckduckgo.com/?q=" },
                        { name: "Brave Search", url: "https://search.brave.com/search?q=" },
                        { name: "Qwant", url: "https://www.qwant.com/?q=" }
                    ]
                    currentIndex: {
                        for (var i = 0; i < model.length; i++) {
                            if (model[i].url === Preferences.launcher.webSearchUrl) return i;
                        }
                        return -1;
                    }
                    onActivated: (index) => {
                        Preferences.launcher.webSearchUrl = model[index].url;
                    }
                }
            }

            SettingsRow {
                icon: "keyboard_command_key"
                label: "Prefix"

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
                        spacing: Theme.geometry.spacing.small

                        Behavior on opacity {
                            NumberAnimation { duration: Theme.animations.fast; easing.type: Easing.OutQuart }
                        }

                        BaseText {
                            text: Preferences.launcher.globalPrefix || "(none)"
                            color: Preferences.launcher.globalPrefix ? Theme.colors.text : Theme.colors.muted
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                        }

                        BaseIcon {
                            icon: "chevron_right"
                            color: Theme.colors.muted
                        }
                    }

                    BaseInput {
                        id: prefixInput
                        anchors.fill: parent
                        opacity: prefixEditor.editing ? 1 : 0
                        visible: opacity > 0
                        enabled: prefixEditor.editing

                        Behavior on opacity {
                            NumberAnimation { duration: Theme.animations.fast; easing.type: Easing.OutQuart }
                        }

                        placeholderText: "e.g. >"
                        selectByMouse: true

                        onAccepted: {
                            Preferences.launcher.globalPrefix = text;
                            prefixEditor.editing = false;
                        }

                        Keys.onPressed: (event) => {
                            if (event.key === Qt.Key_Escape) {
                                prefixInput.text = Preferences.launcher.globalPrefix;
                                prefixEditor.editing = false;
                                event.accepted = true;
                            }
                        }

                        onActiveFocusChanged: {
                            if (!activeFocus && prefixEditor.editing) {
                                if (text !== Preferences.launcher.globalPrefix) {
                                    Preferences.launcher.globalPrefix = text;
                                }
                                prefixEditor.editing = false;
                            }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        enabled: !prefixEditor.editing
                        onClicked: {
                            prefixInput.text = Preferences.launcher.globalPrefix;
                            prefixEditor.editing = true;
                            prefixInput.forceActiveFocus();
                            prefixInput.selectAll();
                        }
                    }
                }
            }

            SettingsRow {
                icon: "description"
                label: "App Descriptions"
                showSeparator: false

                BaseSwitch {
                    checked: Preferences.launcher.showAppDescriptions
                    onToggled: Preferences.launcher.showAppDescriptions = checked
                }
            }
        }
    }
}
