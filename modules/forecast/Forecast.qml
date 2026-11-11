import QtQuick
import QtQuick.Layouts
import Quickshell
import qs

// Current conditions plus a 5-day outlook, opened from the bar's weather block.
// The field under the condition label overrides the ip-api guess; clearing it
// hands the location back. It needs no key guard: nothing here eats keys except
// Escape, so Binds never has to be told to stand aside.
BaseContainer {
    id: root

    readonly property real panelWidth: 275 * Globals.shellScale
    readonly property real currentIconSize: 48 * Globals.shellScale
    readonly property real tempPixelSize: 52 * Globals.shellScale
    readonly property real rowHeight: 26 * Globals.shellScale
    readonly property real dayWidth: 32 * Globals.shellScale
    readonly property real tempWidth: 28 * Globals.shellScale

    readonly property var locale: Qt.locale()

    implicitWidth: panelWidth
    focus: true

    function opening() {
        locationInput.text = Weather.place !== "" ? Weather.place : Weather.city;
        Weather.fetch();
    }

    function commitLocation() {
        var q = locationInput.text;
        if (q === Weather.place || q === Weather.city) return;
        Weather.setLocation(q);
    }

    function iconFor(code) {
        if (code === 0 || code === 1) return "sun";
        if (code === 2) return "cloud-sun";
        if (code === 3) return "cloudy";
        if (code === 45 || code === 48) return "cloud-fog";
        if (code >= 51 && code <= 57) return "cloud-drizzle";
        if (code >= 61 && code <= 67) return "cloud-rain";
        if (code >= 71 && code <= 77) return "cloud-snow";
        if (code >= 80 && code <= 82) return "cloud-rain";
        if (code >= 85 && code <= 86) return "cloud-snow";
        if (code >= 95) return "cloud-lightning";
        return "cloudy";
    }

    function labelFor(code) {
        if (code === 0) return "Clear";
        if (code === 1) return "Mostly Clear";
        if (code === 2) return "Partly Cloudy";
        if (code === 3) return "Overcast";
        if (code === 45 || code === 48) return "Fog";
        if (code >= 51 && code <= 55) return "Drizzle";
        if (code === 56 || code === 57) return "Freezing Drizzle";
        if (code === 61 || code === 63) return "Rain";
        if (code === 65) return "Heavy Rain";
        if (code === 66 || code === 67) return "Freezing Rain";
        if (code === 71 || code === 73 || code === 75) return "Snow";
        if (code === 77) return "Snow Grains";
        if (code >= 80 && code <= 82) return "Showers";
        if (code === 85 || code === 86) return "Snow Showers";
        if (code === 95) return "Thunderstorm";
        if (code === 96 || code === 99) return "Thunderstorm & Hail";
        return "";
    }

    // Qt numbers weekdays 1=Monday..7=Sunday, JS numbers 0=Sunday..6=Saturday.
    function dayName(iso) {
        var p = String(iso).split("-");
        var js = new Date(Number(p[0]), Number(p[1]) - 1, Number(p[2])).getDay();
        return root.locale.dayName(js === 0 ? 7 : js, Locale.ShortFormat);
    }

    // Mouse-only module: right-click anywhere dismisses, and `clickable` stays
    // false so the popout does not shrink under every press.
    onRightClicked: Modules.closeAll()

    ColumnLayout {
        id: mainLayout

        Layout.fillWidth: true
        spacing: Globals.geometry.spacing.md

        RowLayout {
            Layout.fillWidth: true
            spacing: Globals.geometry.spacing.md

            BaseText {
                text: Weather.temp + "°"
                pixelSize: root.tempPixelSize
                font.letterSpacing: 0
                font.features: ({ "tnum": 1 })
                Layout.alignment: Qt.AlignVCenter
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                spacing: Globals.geometry.spacing.xs

                BaseText {
                    Layout.fillWidth: true
                    text: root.labelFor(Weather.code)
                    pixelSize: Globals.typography.size.lg
                    weight: Globals.typography.weight.demi
                    elide: Text.ElideRight
                    wrapMode: Text.NoWrap
                }

                BaseInput {
                    id: locationInput

                    Layout.fillWidth: true

                    placeholderText: "City"
                    font.pixelSize: Globals.typography.size.sm
                    font.capitalization: Font.AllUppercase
                    color: Globals.colors.muted
                    placeholderTextColor: Globals.colors.muted
                    activeFocusOnTab: false

                    onEditingFinished: root.commitLocation()
                    Keys.onReturnPressed: {
                        root.commitLocation();
                        // Clear the field first, then hand focus back to the module
                        // root, so TextInput cannot reclaim it mid-dispatch.
                        locationInput.focus = false;
                        Qt.callLater(root.forceActiveFocus);
                    }
                }
            }

            BaseIcon {
                icon: root.iconFor(Weather.code)
                size: root.currentIconSize
                Layout.alignment: Qt.AlignVCenter
            }
        }

        BaseText {
            Layout.fillWidth: true
            text: "Fetching weather…"
            muted: true
            pixelSize: Globals.typography.size.sm
            visible: !Weather.ready
        }

        // Same shape as the wifi/bluetooth section headings: label left, rule filling
        // the rest, so both pages and this one read the heading the same way.
        RowLayout {
            Layout.fillWidth: true
            spacing: Globals.geometry.spacing.xs
            visible: Weather.daily.length > 0

            BaseHeader {
                text: "5 day"
                Layout.fillWidth: false
                Layout.bottomMargin: 0
            }

            BaseSeparator {
                Layout.alignment: Qt.AlignVCenter
            }
        }

        Repeater {
            model: Weather.daily

            delegate: RowLayout {
                id: dayRow

                required property var modelData

                Layout.fillWidth: true
                Layout.preferredHeight: root.rowHeight
                spacing: Globals.geometry.spacing.sm

                BaseText {
                    Layout.preferredWidth: root.dayWidth
                    text: root.dayName(dayRow.modelData.date)
                    font.capitalization: Font.AllUppercase
                    muted: true
                    pixelSize: Globals.typography.size.sm
                    font.letterSpacing: 1
                }

                BaseIcon {
                    icon: root.iconFor(dayRow.modelData.code)
                    Layout.alignment: Qt.AlignVCenter
                }

                BaseText {
                    Layout.fillWidth: true
                    text: root.labelFor(dayRow.modelData.code)
                    elide: Text.ElideRight
                    wrapMode: Text.NoWrap
                }

                BaseText {
                    Layout.preferredWidth: root.tempWidth
                    horizontalAlignment: Text.AlignRight
                    text: dayRow.modelData.tMax + "°"
                    weight: Globals.typography.weight.demi
                    font.features: ({ "tnum": 1 })
                }
            }
        }
    }
}
