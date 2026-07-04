import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.DBusMenu
import qs
import qs.services

Item {
    id: root
    
    // Position bindings based on external coords
    property real sourceCenterX: 0
    property real sourceTopY: 0
    property real sourceBottomY: 0
    property Item islandItem: null
    
    anchors.fill: parent
    visible: IslandService.isTrayMenuOpen

    // Close menu when clicking outside
    MouseArea {
        anchors.fill: parent
        onClicked: IslandService.isTrayMenuOpen = false
    }

    QsMenuOpener {
        id: menuOpener
    }

    function openMenu(menuHandle, x, y, sourceItem) {
        menuOpener.menu = menuHandle;
        
        // Convert coordinates from sourceItem to this overlay's coordinate system
        var mapped = sourceItem.mapToItem(root, 0, 0);
        
        sourceCenterX = mapped.x + (sourceItem.width / 2);
        sourceTopY = mapped.y;
        sourceBottomY = mapped.y + sourceItem.height;
        
        IslandService.isTrayMenuOpen = true;
    }

    BaseBackground {
        id: menuContainer
        
        x: Math.max(Globals.geometry.padding.medium, Math.min(root.sourceCenterX - (width / 2), root.width - width - Globals.geometry.padding.medium))
        y: {
            if (!islandItem || !islandItem.maskItem) return root.sourceBottomY + Preferences.bar.marginTop;
            return Preferences.bar.position === "bottom" 
                ? islandItem.maskItem.y - height - Preferences.bar.marginTop
                : islandItem.maskItem.y + islandItem.maskItem.height + Preferences.bar.marginTop
        }
        
        width: Math.max(200, layout.implicitWidth + (Globals.geometry.padding.small * 2))
        height: layout.implicitHeight
        
        borderColor: Preferences.globals.islandOutline ? Globals.alpha(Globals.colors.border, 0.4) : Globals.colors.transparent
        borderWidth: Preferences.globals.islandOutline ? 1 : 0
        radius: Preferences.globals.cornerRadius || Globals.geometry.radius
        
        // Prevent clicks from falling through to the background
        MouseArea { anchors.fill: parent }

        readonly property Item activeHover: {
            for (var i = 0; i < menuRepeater.count; i++) {
                var item = menuRepeater.itemAt(i);
                if (item && item.isHovered) return item;
            }
            return null;
        }

        function _hoverPredicate() {
            return menuContainer.activeHover;
        }

        Item {
            anchors.fill: parent
            anchors.leftMargin: Globals.geometry.padding.small
            anchors.rightMargin: Globals.geometry.padding.small

            ColumnLayout {
                id: layout
                anchors.fill: parent
                spacing: 0
            
            Repeater {
                id: menuRepeater
                model: menuOpener.children
                
                delegate: Item {
                    id: delegateItem
                    Layout.fillWidth: true
                    visible: modelData.visible !== false && !modelData.isSeparator
                    
                    implicitHeight: listItem.implicitHeight
                    
                    property bool isHovered: listItem.visible && listItem.hovered
                    
                    BaseListItem {
                        id: listItem
                        visible: !modelData.isSeparator
                        anchors.fill: parent
                        
                        title: modelData.text ? modelData.text.replace(/&/g, '') : ""
                        titleSize: Globals.typography.size.base
                        leftImage: modelData.icon || ""
                        leftIconInteractive: false
                        showInternalIndicator: false
                        
                        rightIcon: modelData.hasChildren ? "chevron_right" : ""
                        rightIconVisible: modelData.hasChildren
                        
                        opacity: modelData.enabled ? 1.0 : 0.5
                        
                        onClicked: {
                            if (!modelData.enabled) return;
                            
                            if (modelData.hasChildren) {
                                console.log("Submenu clicked");
                            } else {
                                modelData.triggered();
                                IslandService.isTrayMenuOpen = false;
                            }
                        }
                    }
                }
            }
        }

            BaseIndicator {
                hoverPredicate: menuContainer._hoverPredicate
            }
        }
    }
}
