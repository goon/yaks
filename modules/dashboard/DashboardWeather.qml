import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs

BaseBento {
    id: weather
    implicitWidth: 360
    implicitHeight: 160

    ColumnLayout {
        id: weatherWidget
        Layout.fillWidth: true
        Layout.fillHeight: true
        spacing: Globals.geometry.spacing.medium

        property bool editMode: false
        readonly property bool isDay: Weather.isDay
        readonly property int code: Weather.weatherCode

        function getIcon(code, isDay) {
            if (code === 0)
                return isDay ? "clear_day" : "clear_night";
            if (code >= 1 && code <= 3)
                return isDay ? "partly_cloudy_day" : "partly_cloudy_night";
            if (code >= 45 && code <= 48)
                return "foggy";
            if (code >= 51 && code <= 67)
                return "rainy";
            if (code >= 71 && code <= 77)
                return "weather_snowy";
            if (code >= 80 && code <= 82)
                return "rainy";
            if (code >= 85 && code <= 86)
                return "weather_snowy";
            if (code >= 95 && code <= 99)
                return "thunderstorm";
            return "question_mark";
        }

        // Header Area: Location Display or Search ComboBox
        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: 32

            // Location Display Header
            Item {
                id: locationHeader
                anchors.fill: parent
                visible: !weatherWidget.editMode

                RowLayout {
                    id: locationHeaderRow
                    anchors.fill: parent
                    spacing: Globals.geometry.spacing.small

                    BaseIcon {
                        id: locIcon
                        icon: locationMouseArea.containsMouse ? "edit" : "location_on"
                        size: 18
                        color: Globals.colors.primary

                        onIconChanged: iconAnim.restart()

                        SequentialAnimation {
                            id: iconAnim
                            BaseAnimation { target: locIcon; property: "scale"; from: 1.0; to: 0.7 }
                            BaseAnimation { target: locIcon; property: "scale"; to: 1.0; easing.type: Easing.OutBack }
                        }
                    }

                    BaseText {
                        text: Preferences.weather.locationName
                        font.pixelSize: Globals.typography.size.medium
                        weight: Globals.typography.weights.bold
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }
                }

                MouseArea {
                    id: locationMouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: weatherWidget.editMode = true
                }
            }

            // Location Search ComboBox (when editing)
            BaseComboBox {
                id: locationSearch
                anchors.fill: parent
                visible: weatherWidget.editMode
                opacity: visible ? 1 : 0
                model: Weather.searchResults
                textRole: "full_name"
                searchable: true
                filterLocally: false
                displayText: Preferences.weather.locationName || "Search location..."

                onSearchTextChanged: Weather.searchLocation(searchText)

                onActivated: (index) => {
                    var item = Weather.searchResults[index];
                    if (item) {
                        Preferences.weather.lat = item.latitude.toString();
                        Preferences.weather.long = item.longitude.toString();
                        Preferences.weather.locationName = item.full_name;
                        weatherWidget.editMode = false;
                    }
                }

                Behavior on opacity { BaseAnimation { } }

                onVisibleChanged: {
                    if (visible) forceActiveFocus();
                }
            }
        }

        BaseSeparator {
            Layout.fillWidth: true
            opacity: 0.2
        }

        // Bottom Content Area: Stats (left) and Weather Display (right)
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            RowLayout {
                anchors.fill: parent
                spacing: Globals.geometry.spacing.large

                // Left Column: Humidity and Wind Details
                ColumnLayout {
                    spacing: Globals.geometry.spacing.small
                    Layout.alignment: Qt.AlignVCenter

                    // Humidity
                    RowLayout {
                        spacing: Globals.geometry.spacing.small
                        BaseIcon { icon: "humidity_mid"; size: 16; color: Globals.colors.primary }
                        ColumnLayout {
                            spacing: 0
                            BaseText { text: "Humidity"; font.pixelSize: 10; muted: true; weight: Globals.typography.weights.bold }
                            BaseText { text: Weather.humidity; font.pixelSize: Globals.typography.size.medium; weight: Globals.typography.weights.bold }
                        }
                    }

                    // Wind
                    RowLayout {
                        spacing: Globals.geometry.spacing.small
                        BaseIcon { icon: "air"; size: 16; color: Globals.colors.primary }
                        ColumnLayout {
                            spacing: 0
                            BaseText { text: "Wind"; font.pixelSize: 10; muted: true; weight: Globals.typography.weights.bold }
                            BaseText { text: Weather.windSpeed; font.pixelSize: Globals.typography.size.medium; weight: Globals.typography.weights.bold }
                        }
                    }
                }

                // Spacer pushing left and right blocks apart
                Item { Layout.fillWidth: true }

                // Right Column: Weather Icon & Temperature Details
                RowLayout {
                    spacing: Globals.geometry.spacing.large
                    Layout.alignment: Qt.AlignVCenter

                    // Icon Container (handles animations)
                    Item {
                        Layout.preferredWidth: 64
                        Layout.preferredHeight: 64
                        Layout.alignment: Qt.AlignVCenter

                        BaseIcon {
                            id: mainIcon
                            anchors.centerIn: parent
                            icon: weatherWidget.getIcon(weatherWidget.code, weatherWidget.isDay)
                            size: 64
                            color: Globals.colors.primary
                        }

                        // Rotation animation for sun icons
                        RotationAnimation {
                            id: sunRotation
                            target: mainIcon
                            property: "rotation"
                            from: 0
                            to: 360
                            duration: 25000 // 25s slow rotation
                            loops: Animation.Infinite
                            running: mainIcon.icon === "clear_day"
                            onRunningChanged: {
                                if (!running) {
                                    mainIcon.rotation = 0;
                                }
                            }
                        }

                        // Floating/drifting animation for clouds/rain/snow/storm icons
                        SequentialAnimation {
                            id: cloudFloat
                            running: mainIcon.icon !== "clear_day" && mainIcon.icon !== ""
                            loops: Animation.Infinite

                            NumberAnimation {
                                target: mainIcon
                                property: "anchors.verticalCenterOffset"
                                from: 0
                                to: -3
                                duration: 2500
                                easing.type: Easing.OutCubic
                            }

                            NumberAnimation {
                                target: mainIcon
                                property: "anchors.verticalCenterOffset"
                                from: -3
                                to: 0
                                duration: 2500
                                easing.type: Easing.OutCubic
                            }

                            onRunningChanged: {
                                if (!running) {
                                    mainIcon.anchors.verticalCenterOffset = 0;
                                }
                            }
                        }
                    }

                    ColumnLayout {
                        spacing: -Globals.geometry.spacing.small
                        BaseText {
                            text: Weather.temperature
                            font.pixelSize: 42
                            weight: Globals.typography.weights.bold
                        }
                        BaseText {
                            text: "FEELS LIKE " + Weather.feelsLike
                            font.pixelSize: 11
                            weight: Globals.typography.weights.bold
                            muted: true
                        }
                    }
                }
            }
        }

        // Error message if any
        BaseText {
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            text: Weather.error
            visible: Weather.error !== ""
            font.pixelSize: Globals.typography.size.small
            color: Globals.colors.error
        }
    }
}
