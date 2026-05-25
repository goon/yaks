import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs

BaseBlock {
    id: weather
    implicitWidth: 360
    implicitHeight: 160

    ColumnLayout {
        id: weatherWidget
        Layout.fillWidth: true
        Layout.fillHeight: true
        spacing: Theme.geometry.spacing.medium

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
                    spacing: Theme.geometry.spacing.small

                    BaseIcon {
                        id: locIcon
                        icon: locationMouseArea.containsMouse ? "edit" : "location_on"
                        size: 18
                        color: Theme.colors.primary

                        onIconChanged: iconAnim.restart()

                        SequentialAnimation {
                            id: iconAnim
                            BaseAnimation { target: locIcon; property: "scale"; from: 1.0; to: 0.7; speed: "fast" }
                            BaseAnimation { target: locIcon; property: "scale"; to: 1.0; speed: "fast"; easing.type: Easing.OutBack }
                        }
                    }

                    BaseText {
                        text: Preferences.weatherLocationName
                        font.pixelSize: Theme.typography.size.medium
                        color: Theme.colors.text
                        weight: Theme.typography.weights.bold
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
                displayText: Preferences.weatherLocationName || "Search location..."

                onSearchTextChanged: Weather.searchLocation(searchText)

                onActivated: (index) => {
                    var item = Weather.searchResults[index];
                    if (item) {
                        Preferences.weatherLat = item.latitude.toString();
                        Preferences.weatherLong = item.longitude.toString();
                        Preferences.weatherLocationName = item.full_name;
                        weatherWidget.editMode = false;
                    }
                }

                Behavior on opacity { BaseAnimation { speed: "fast" } }

                onVisibleChanged: {
                    if (visible) forceActiveFocus();
                }
            }
        }

        // Horizontal Separator
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
                spacing: Theme.geometry.spacing.large

                // Left Column: Humidity and Wind Details
                ColumnLayout {
                    spacing: Theme.geometry.spacing.small
                    Layout.alignment: Qt.AlignVCenter

                    // Humidity
                    RowLayout {
                        spacing: Theme.geometry.spacing.small
                        BaseIcon { icon: "humidity_mid"; size: 16; color: Theme.colors.primary }
                        ColumnLayout {
                            spacing: 0
                            BaseText { text: "Humidity"; font.pixelSize: 10; color: Theme.colors.muted; weight: Theme.typography.weights.bold }
                            BaseText { text: Weather.humidity; font.pixelSize: Theme.typography.size.medium; color: Theme.colors.text; weight: Theme.typography.weights.bold }
                        }
                    }

                    // Wind
                    RowLayout {
                        spacing: Theme.geometry.spacing.small
                        BaseIcon { icon: "air"; size: 16; color: Theme.colors.primary }
                        ColumnLayout {
                            spacing: 0
                            BaseText { text: "Wind"; font.pixelSize: 10; color: Theme.colors.muted; weight: Theme.typography.weights.bold }
                            BaseText { text: Weather.windSpeed; font.pixelSize: Theme.typography.size.medium; color: Theme.colors.text; weight: Theme.typography.weights.bold }
                        }
                    }
                }

                // Spacer pushing left and right blocks apart
                Item { Layout.fillWidth: true }

                // Right Column: Weather Icon & Temperature Details
                RowLayout {
                    spacing: Theme.geometry.spacing.large
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
                            color: Theme.colors.primary
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

                    // Temperature Details Column
                    ColumnLayout {
                        spacing: -Theme.geometry.spacing.small
                        BaseText {
                            text: Weather.temperature
                            font.pixelSize: 42
                            weight: Theme.typography.weights.bold
                            color: Theme.colors.text
                        }
                        BaseText {
                            text: "FEELS LIKE " + Weather.feelsLike
                            font.pixelSize: 11
                            weight: Theme.typography.weights.bold
                            color: Theme.colors.muted
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
            font.pixelSize: Theme.typography.size.small
            color: Theme.colors.error
        }
    }
}
