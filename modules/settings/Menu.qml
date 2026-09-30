import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs

Item {
    id: root
    implicitHeight: mainCol.implicitHeight
    Layout.fillWidth: true

    property string title: "Settings"

    function pushPage(name) {
        StackView.view.pushPage(Qt.resolvedUrl(name), name);
    }

    // ── SINGLE SOURCE OF TRUTH ──────────────────────────────────────────

    readonly property var _menuModel: [
        { page: "Style.qml",         title: "Style",         icon: "paintbrush"  },
        { page: "Bar.qml",           title: "Bar",           icon: "panel-top"   },
        { page: "Wallpaper.qml",     title: "Wallpaper",     icon: "image"       },
        { page: "Applications.qml",  title: "Applications",  icon: "layout-grid" },
    ]

    readonly property Item activeHover: {
        for (var i = 0; i < menuRepeater.count; i++) {
            var item = menuRepeater.itemAt(i);
            if (item && item.hovered) return item;
        }
        return null;
    }

    function _hoverPredicate() {
        // A hovered item always wins, so the pointer can take over from the
        // keyboard immediately; the keyboard highlight only shows when nothing
        // is hovered.
        if (mixerItem.hoveredSlider) return mixerItem.hoveredSlider;
        if (root.activeHover) return root.activeHover;
        for (var i = 0; i < menuRepeater.count; i++) {
            var navItem = menuRepeater.itemAt(i);
            if (navItem && navItem.navHighlighted) return navItem;
        }
        return null;
    }

    ColumnLayout {
        id: mainCol
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right

        Repeater {
            id: menuRepeater
            model: root._menuModel

            delegate: BaseListItem {
                required property int index
                required property var modelData

                Layout.fillWidth: true
                title: modelData.title
                bounceTitleOnHover: true
                itemHeight: SettingsRow.rowHeight
                leftIconBoxSize: Globals.dimensions.barItemHeight
                leftIcon: modelData.icon
                onClicked: root.pushPage(modelData.page)
            }
        }

        BaseSeparator {
            Layout.fillWidth: true
            Layout.topMargin: Globals.geometry.spacing.medium
            Layout.bottomMargin: Globals.geometry.spacing.medium
        }

        SettingsMixer {
            id: mixerItem
            Layout.fillWidth: true
        }
    }

    BaseIndicator {
        hoverPredicate: root._hoverPredicate
        gapInterval: Globals.motion.hover
    }
}
