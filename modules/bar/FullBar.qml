import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.services
import qs

Item {
    id: fullBarRoot
    
    property var barWindow: null
    
    readonly property real localBarScale: Globals.barScale
    
    // Explicitly define height matching the pill clock capsule height
    implicitHeight: Preferences.bar.height
    implicitWidth: (contentLayout.implicitWidth || 0) * localBarScale + (dynamicEndMargin * 2)
    
    readonly property real normalSideMargin: 0
    readonly property real dynamicEndMargin: Globals.geometry.padding.island
    readonly property real horizontalSpacing: 20 / localBarScale

    RowLayout {
        id: contentLayout
        
        anchors.verticalCenter: parent.verticalCenter
        anchors.horizontalCenter: parent.horizontalCenter
        height: implicitHeight
        width: mainContent.implicitWidth
        spacing: horizontalSpacing
        
        transform: Scale {
            origin.x: contentLayout.width / 2
            origin.y: contentLayout.height / 2
            xScale: localBarScale
            yScale: localBarScale
        }
        
        RowLayout {
            id: mainContent
            Layout.alignment: Qt.AlignCenter | Qt.AlignVCenter
            spacing: horizontalSpacing
            
            Repeater {
                model: barWindow ? barWindow.components : []
                
                RowLayout {
                    Layout.alignment: Qt.AlignVCenter
                    visible: (Preferences.bar.componentsEnabled[modelData] === true) && (modelData === "dock" ? Compositor.hasDockWindows : (barWindow && barWindow.resolveComponentSource(modelData) !== ""))
                    spacing: horizontalSpacing
                    
                    BaseSeparator {
                        visible: {
                            if (!parent.visible) return false;
                            let visibleIndex = -1;
                            for (let i = 0; i < mainContent.visibleChildren.length; i++) {
                                if (mainContent.visibleChildren[i] === parent) {
                                    visibleIndex = i;
                                    break;
                                }
                            }
                            return visibleIndex > 0;
                        }
                        orientation: BaseSeparator.Vertical
                        Layout.fillHeight: false
                        Layout.preferredHeight: 30
                        Layout.preferredWidth: 1
                        Layout.alignment: Qt.AlignVCenter
                        color: Globals.colors.border
                    }

                    Loader {
                        id: componentLoader
                        Layout.alignment: Qt.AlignVCenter
                        source: barWindow ? barWindow.resolveComponentSource(modelData) : ""
                        Binding {
                            target: componentLoader.item
                            property: "barWindow"
                            value: barWindow
                            when: componentLoader.item !== null && modelData === "indicators"
                        }
                    }
                }
            }
        }
    }
}
