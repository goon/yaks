import QtQuick
import QtQuick.Layouts
import qs

SettingsPage {
    id: root

    title: "Shell Configuration"

    ColumnLayout {
        Layout.fillWidth: true
        spacing: Theme.geometry.spacing.medium

        BaseText {
            text: "Use the sub-pages in the sidebar to configure specific areas of the shell — Globals, Bar, and Workspaces."
            color: Theme.colors.text
            pixelSize: Theme.typography.size.medium
            Layout.fillWidth: true
            Layout.preferredWidth: 0
            wrapMode: Text.WordWrap
        }
    }
}
