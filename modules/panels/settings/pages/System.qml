import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs

SettingsPage {
    id: root

    title: "System Configuration"

    Component.onCompleted: {
        ThemeService.refreshThemeService();
        ThemeService.scanThemeServices();
    }

    GridLayout {
        columns: 2
        rowSpacing: Theme.geometry.spacing.dynamicPadding
        columnSpacing: Theme.geometry.spacing.dynamicPadding
        Layout.fillWidth: true

        BaseText {
            text: "Configure system-wide visual elements like theme, icons, and fonts."
            color: Theme.colors.text
            pixelSize: Theme.typography.size.medium
            Layout.fillWidth: true
            Layout.columnSpan: 2
            Layout.bottomMargin: Theme.geometry.spacing.small
        }

        RowLayout {
            Layout.columnSpan: 2
            Layout.fillWidth: true
            spacing: Theme.geometry.spacing.large
            Layout.bottomMargin: Theme.geometry.spacing.medium

            // Dark Mode Hero Card
            BaseBlock {
                id: darkCard
                Layout.fillWidth: true
                Layout.preferredHeight: 100
                clickable: true
                premiumActive: isActive
                borderWidth: 1
                borderColor: Theme.colors.border
                padding: Theme.geometry.spacing.medium
                
                readonly property bool isActive: ThemeService.colorScheme === 'prefer-dark'

                onClicked: {
                    if (!isActive) ThemeService.toggleColorScheme();
                }

                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: Theme.geometry.spacing.small

                        BaseIcon {
                            icon: "dark_mode"
                            size: Theme.dimensions.iconLarge
                            color: darkCard.isActive ? Theme.colors.primary : Theme.colors.text
                            Layout.alignment: Qt.AlignHCenter
                        }

                        BaseText {
                            text: "Dark Mode"
                            weight: Theme.typography.weights.bold
                            pixelSize: Theme.typography.size.medium
                            color: darkCard.isActive ? Theme.colors.textLighter : Theme.colors.text
                            Layout.alignment: Qt.AlignHCenter
                        }
                    }
                }
            }

            // Light Mode Hero Card
            BaseBlock {
                id: lightCard
                Layout.fillWidth: true
                Layout.preferredHeight: 100
                clickable: true
                premiumActive: isActive
                borderWidth: 1
                borderColor: Theme.colors.border
                padding: Theme.geometry.spacing.medium
                
                readonly property bool isActive: ThemeService.colorScheme !== 'prefer-dark'

                onClicked: {
                    if (!isActive) ThemeService.toggleColorScheme();
                }

                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: Theme.geometry.spacing.small

                        BaseIcon {
                            icon: "light_mode"
                            size: Theme.dimensions.iconLarge
                            color: lightCard.isActive ? Theme.colors.primary : Theme.colors.text
                            Layout.alignment: Qt.AlignHCenter
                        }

                        BaseText {
                            text: "Light Mode"
                            weight: Theme.typography.weights.bold
                            pixelSize: Theme.typography.size.medium
                            color: lightCard.isActive ? Theme.colors.textLighter : Theme.colors.text
                            Layout.alignment: Qt.AlignHCenter
                        }
                    }
                }
            }
        }

        // GTK Theme
        BaseText {
            text: "GTK Theme:"
            pixelSize: Theme.typography.size.medium
        }

        BaseComboBox {
            Layout.fillWidth: true
            model: ThemeService.availableGtkThemes
            currentIndex: ThemeService.findIndexCaseInsensitive(model, ThemeService.gtkTheme)
            onActivated: (index) => {
                ThemeService.setGtkTheme(model[index]);
            }
        }

        // Icon Theme
        BaseText {
            text: "Icon Theme:"
            pixelSize: Theme.typography.size.medium
        }

        BaseComboBox {
            Layout.fillWidth: true
            model: ThemeService.availableIconThemes
            currentIndex: ThemeService.findIndexCaseInsensitive(model, ThemeService.iconTheme)
            onActivated: (index) => {
                ThemeService.setIconTheme(model[index]);
            }
        }

        // Font Name & Size
        BaseText {
            text: "Font:"
            pixelSize: Theme.typography.size.medium
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.geometry.spacing.large

            BaseComboBox {
                Layout.fillWidth: true
                model: ThemeService.getCleanFontFamilies()
                searchable: true
                previewFonts: true
                currentIndex: {
                    var current = ThemeService.fontName;
                    for (var i = 0; i < model.length; i++) {
                        if (current.indexOf(model[i]) === 0)
                            return i;
                    }
                    return -1;
                }
                onActivated: (index) => {
                    var family = model[index];
                    var current = ThemeService.fontName;
                    var match = current.match(/\s\d+$/);
                    var size = match ? match[0] : " 11";
                    ThemeService.setFontName(family + size);
                }
            }

            BaseSpinBox {
                from: 6
                to: 72
                Layout.preferredWidth: 80
                Layout.preferredHeight: 42
                value: {
                    var match = ThemeService.fontName.match(/(\d+)$/);
                    return match ? parseInt(match[1]) : 11;
                }
                onValueModified: {
                    ThemeService.setFontSize(value);
                }
            }
        }

        // Cursor Theme
        BaseText {
            text: "Cursor Theme:"
            pixelSize: Theme.typography.size.medium
        }

        BaseComboBox {
            Layout.fillWidth: true
            model: ThemeService.availableCursorThemes
            currentIndex: ThemeService.findIndexCaseInsensitive(model, ThemeService.cursorTheme)
            onActivated: (index) => {
                if (index >= 0)
                    ThemeService.setCursorTheme(model[index]);
            }
        }

        // Cursor Size
        BaseText {
            text: "Cursor Size:"
            pixelSize: Theme.typography.size.medium
        }

        BaseComboBox {
            Layout.fillWidth: true
            model: [24, 32, 48, 64, 96]
            currentIndex: {
                if (!model)
                    return -1;

                var size = ThemeService.cursorSize;
                return model.indexOf(size);
            }
            onActivated: (index) => {
                if (index >= 0)
                    ThemeService.setCursorSize(model[index]);
            }
        }

        BaseSeparator {
            Layout.fillWidth: true
            Layout.columnSpan: 2
            Layout.topMargin: Theme.geometry.spacing.medium
            Layout.bottomMargin: Theme.geometry.spacing.medium
        }

        BaseText {
            text: "Themed Applications"
            weight: Theme.typography.weights.bold
            color: Theme.colors.primary
            pixelSize: Theme.typography.size.large
            Layout.columnSpan: 2
            Layout.topMargin: Theme.geometry.spacing.small
        }

        BaseText {
            text: "Controls the themeing of various applications on a per application basis. Disclaimer: This overrides various configuration files and can be destructive."
            color: Theme.colors.text
            pixelSize: Theme.typography.size.medium
            Layout.fillWidth: true
            Layout.preferredWidth: 0
            Layout.columnSpan: 2
            Layout.bottomMargin: Theme.geometry.spacing.small
        }

        BaseText {
            text: "Themed Apps Opacity:"
            pixelSize: Theme.typography.size.medium
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.geometry.spacing.large

            BaseSlider {
                id: appsOpacitySlider

                Layout.fillWidth: true
                from: 0.3
                to: 1.0
                stepSize: 0.05
                value: Preferences.themedAppsOpacity
                onMoved: Preferences.themedAppsOpacity = value
            }

            BaseText {
                text: Math.round(appsOpacitySlider.value * 100) + "%"
                Layout.preferredWidth: 40
                horizontalAlignment: Text.AlignRight
            }
        }

        // Flow of themed apps
        Flow {
            Layout.columnSpan: 2
            Layout.fillWidth: true
            spacing: Theme.geometry.spacing.small

            Repeater {
                model: ThemeRegistration.applications

                delegate: Item {
                    id: pill

                    readonly property bool isInstalled: ThemeService.installedApps[modelData.id] !== false
                    readonly property bool isEnabled: (Preferences.themedApps[modelData.id] || false) && isInstalled

                    width: innerRow.width + Theme.geometry.spacing.medium * 2
                    height: innerRow.height + Theme.geometry.spacing.small * 2
                    opacity: isInstalled ? 1 : 0.5

                    // 1. Premium Selection Gradient Border (Active)
                    Rectangle {
                        anchors.fill: parent
                        radius: Theme.geometry.radius
                        visible: pill.isEnabled
                        gradient: Gradient {
                            orientation: Gradient.Horizontal
                            GradientStop { position: 0; color: Theme.colors.primary }
                            GradientStop { position: 1; color: Theme.colors.secondary }
                        }
                    }

                    // 2. Inner Cutout (Active)
                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: 1.5
                        radius: Theme.geometry.radius - 1.5
                        visible: pill.isEnabled
                        color: Theme.colors.surface

                        Rectangle {
                            anchors.fill: parent
                            radius: parent.radius
                            color: Qt.alpha(Theme.colors.primary, 0.08)
                        }
                    }

                    // 3. Inactive Border (Inactive)
                    Rectangle {
                        anchors.fill: parent
                        radius: Theme.geometry.radius
                        visible: !pill.isEnabled
                        color: Theme.colors.transparent
                        border.width: 1
                        border.color: Theme.colors.border
                    }

                    Row {
                        id: innerRow
                        anchors.centerIn: parent
                        spacing: 6

                        BaseIcon {
                            icon: pill.isEnabled ? "check_circle" : "circle"
                            fill: false
                            size: 14
                            color: pill.isEnabled ? Theme.colors.primary : Theme.colors.border
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        BaseText {
                            id: label
                            text: modelData.name
                            color: pill.isEnabled ? Theme.colors.textLighter : Theme.colors.text
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    BaseTooltip {
                        visible: mouseArea.containsMouse
                        text: modelData.path
                    }

                    MouseArea {
                        id: mouseArea
                        anchors.fill: parent
                        enabled: pill.isInstalled
                        hoverEnabled: true
                        onClicked: {
                            let apps = JSON.parse(JSON.stringify(Preferences.themedApps));
                            apps[modelData.id] = !pill.isEnabled;
                            Preferences.themedApps = apps;
                        }
                    }
                }
            }
        }
    }
}
