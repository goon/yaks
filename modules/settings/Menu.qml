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
        StackView.view.push(name);
    }

    // ── SINGLE SOURCE OF TRUTH ──────────────────────────────────────────

    readonly property var _menuModel: [
        { page: "Style.qml",         title: "Style",         icon: "paintbrush"  },
        { page: "Bar.qml",           title: "Bar",           icon: "panel-top"   },
        { page: "Animations.qml",    title: "Animations",    icon: "zap"         },
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
        // Keyboard navigation wins over hover.
        if (mixerItem.hoveredSlider) return mixerItem.hoveredSlider;
        for (var i = 0; i < menuRepeater.count; i++) {
            var navItem = menuRepeater.itemAt(i);
            if (navItem && navItem.navHighlighted) return navItem;
        }
        return root.activeHover;
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
                itemHeight: Globals.dimensions.settingsRowHeight
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
        gapInterval: Globals.animations.fast
    }
}
