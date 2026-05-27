import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs

DashboardPage {
    id: root
    implicitHeight: mainRow.implicitHeight

    RowLayout {
        id: mainRow
        Layout.fillWidth: true
        Layout.fillHeight: true
        spacing: Theme.geometry.spacing.large

        // Left + Middle Column Group
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: Theme.geometry.spacing.large

            // Top Row: Weather & User Panel
            RowLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.preferredHeight: 160
                spacing: Theme.geometry.spacing.large

                DashboardUserPanel {
                    id: userPanel
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                }

                DashboardWeather {
                    id: weather
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                }
            }

            // Bottom Row: Clock & Calendar & Resource Bars
            RowLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.preferredHeight: 320
                spacing: Theme.geometry.spacing.large

                DashboardClock {
                    id: clock
                    Layout.fillHeight: true
                }

                DashboardCalendar {
                    id: calendar
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                }

                DashboardResourceBars {
                    id: resourceBars
                    Layout.fillHeight: true
                    onClicked: root.StackView.view.replace("Performance.qml")
                }
            }
        }

        // Right Column: Media Player
        DashboardMedia {
            id: media
            Layout.fillHeight: true
        }
    }
}
