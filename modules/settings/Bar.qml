import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs

SettingsPage {
    id: root

    title: "Bar"
    description: "Configure the position, size, and layout of the system bar."

    ColumnLayout {
        Layout.fillWidth: true
        spacing: Globals.geometry.spacing.large

        SettingsGroup {
            Layout.fillWidth: true

            SettingsRow {
                icon: "border_top"
                label: "Position"

                BaseSegmentedControl {
                    Layout.fillWidth: true
                    model: [{ "label": "Top", "value": "top" }, { "label": "Bottom", "value": "bottom" }]
                    currentValue: Preferences.bar.position
                    onActivated: (index, value) => {
                        Preferences.bar.position = value;
                    }
                }
            }

            SettingsRow {
                icon: "view_quilt"
                label: "Density"

                BaseSegmentedControl {
                    Layout.fillWidth: true
                    model: [
                        { "label": "0.9x", "value": 0 },
                        { "label": "1.0x", "value": 1 },
                        { "label": "1.1x", "value": 2 }
                    ]
                    currentValue: Preferences.bar.density
                    onActivated: (index, value) => {
                        Preferences.bar.density = value;
                    }
                }
            }

            SettingsRow {
                icon: "space_bar"
                label: "Margin"

                BaseSpinBox {
                    from: 0
                    to: 50
                    stepSize: 1
                    value: Preferences.bar.marginTop
                    suffix: "px"
                    onValueChanged: Preferences.bar.marginTop = value
                }
            }

            SettingsRow {
                icon: "view_module"
                label: "Workspace Count"
                showSeparator: false

                BaseSpinBox {
                    from: 1
                    to: 20
                    value: Preferences.bar.workspaceCount
                    onValueChanged: Preferences.bar.workspaceCount = value
                }
            }

            BarConfiguration {
                Layout.fillWidth: true
            }
        }
    }

    // ── BarConfiguration component ────────────────────────────────────────
    component BarConfiguration: ColumnLayout {
        id: barRoot

        readonly property var componentMetadata: ({
            "workspaces": { name: "Workspaces", icon: "view_week" },
            "clock":      { name: "Clock",      icon: "schedule"  },
            "dock":       { name: "Dock",        icon: "vertical_split" },
            "indicators": { name: "Indicators",  icon: "stacks"   },
        })


        function getList(listName) {
            if (listName === "barComponents") return Array.from(Preferences.bar.components);
            return [];
        }

        function updateList(listName, list) {
            if (listName === "barComponents") Preferences.bar.components = list;
        }

        function moveComponent(componentId, sourceSection, targetSection, targetIndex) {
            if (sourceSection !== targetSection) return;

            var targetList = getList(targetSection);
            var sourceIndex = targetList.indexOf(componentId);
            
            if (sourceIndex > -1) {
                targetList.splice(sourceIndex, 1);
                if (targetIndex === -1 || targetIndex >= targetList.length) {
                    targetList.push(componentId);
                } else {
                    targetList.splice(targetIndex, 0, componentId);
                }
                updateList(targetSection, targetList);
            }
        }

        property color primaryColor: Globals.colors.primary
        Layout.fillWidth: true

        ColumnLayout {
            Layout.fillWidth: true
            spacing: Globals.geometry.spacing.medium



            ComponentList {
                Layout.fillWidth: true
                sectionName: "barComponents"
                components: Preferences.bar.components
            }
        }
    }

    // ── BarComponentItem ─────────────────────────────────────────────────
    component BarComponentItem: Item {
        id: itemRoot

        property string componentId
        property string sourceSection
        property string label
        property var dragData: ({ componentId: componentId, sourceSection: sourceSection })

        width:  rect.width
        height: rect.height
        opacity: dragHandler.drag.active ? 0.3 : 1.0

        Rectangle {
            id: rect
            property var  dragData: itemRoot.dragData
            readonly property bool isActive: dragHandler.containsMouse || dragHandler.drag.active
            readonly property bool isEnabled: Preferences.bar.componentsEnabled[itemRoot.componentId] === true

            width:  innerLayout.width  + Globals.geometry.spacing.medium * 2
            height: Globals.dimensions.iconBase + Globals.geometry.spacing.small  * 2

            radius: Globals.geometry.radius

            // Outer border/color for inactive available components
            color:        Globals.colors.transparent
            border.width: !rect.isEnabled ? 1 : 0
            border.color: Globals.colors.border

            // Premium gradient layer (visible for active sections OR when hovered/dragged)
            Rectangle {
                anchors.fill: parent
                radius: parent.radius
                visible: rect.isEnabled
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0.0; color: Globals.colors.primary }
                    GradientStop { position: 1.0; color: Globals.colors.secondary }
                }
            }

            // Cutout/Inner background layer
            Rectangle {
                anchors.fill: parent
                anchors.margins: 1.5
                radius: parent.radius - anchors.margins
                visible: rect.isEnabled
                color: Globals.colors.surface

                // Overlay primary tint for premium active section items
                Rectangle {
                    anchors.fill: parent
                    radius: parent.radius
                    color: Qt.alpha(Globals.colors.primary, 0.08)
                }
            }

            // Drag handler covering the entire background of the pill
            MouseArea {
                id: dragHandler
                anchors.fill: parent
                acceptedButtons: Qt.LeftButton
                drag.target: rect
                drag.axis:   Drag.XAndYAxis
                cursorShape: drag.active ? Qt.ClosedHandCursor : Qt.OpenHandCursor

                onReleased: { rect.Drag.drop(); rect.x = 0; rect.y = 0; }

                onClicked: (mouse) => {
                    let map = JSON.parse(JSON.stringify(Preferences.bar.componentsEnabled));
                    map[componentId] = !rect.isEnabled;
                    Preferences.bar.componentsEnabled = map;
                }
            }

            Row {
                id: innerLayout
                anchors.centerIn: parent
                spacing: 6

                BaseIcon {
                    icon:  barRoot.componentMetadata[itemRoot.componentId]?.icon || "extension"
                    size:  Globals.dimensions.iconBase
                    color: rect.isEnabled ? Globals.colors.primary : Globals.colors.text
                    anchors.verticalCenter: parent.verticalCenter
                }

                BaseText {
                    text:  itemRoot.label
                    color: rect.isEnabled ? Globals.colors.textLighter : Globals.colors.text
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            Drag.active:    dragHandler.drag.active
            Drag.keys:      ["bar-component"]
            Drag.hotSpot.x: width  / 2
            Drag.hotSpot.y: height / 2

            states: [
                State {
                    when: dragHandler.drag.active
                    ParentChange { target: rect; parent: root }
                    AnchorChanges {
                        target: rect
                        anchors.horizontalCenter: undefined
                        anchors.verticalCenter:   undefined
                    }
                }
            ]
        }
    }

    // ── ComponentList ────────────────────────────────────────────────────
    component ComponentList: ColumnLayout {
        id: section

        required property string sectionName
        required property var    components

        spacing: Globals.geometry.spacing.small

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: Math.max(flow.height, 50)
            color:        dropArea.containsDrag ? Globals.alpha(barRoot.primaryColor, 0.1) : Globals.colors.transparent
            radius:       Globals.geometry.radius
            border.width: 1
            border.color: dropArea.containsDrag ? Globals.colors.primary : Globals.colors.transparent

            DropArea {
                id: dropArea
                anchors.fill: parent
                keys: ["bar-component"]
                onDropped: (drop) => {
                    var data = drop.source && drop.source.dragData;
                    if (!data) return;
                    barRoot.moveComponent(data.componentId, data.sourceSection, section.sectionName, -1);
                    drop.accept();
                }
            }



            Flow {
                id: flow
                anchors.top:   parent.top
                anchors.left:  parent.left
                anchors.right: parent.right
                anchors.margins: 4
                spacing: Globals.geometry.spacing.small

                Repeater {
                    model: components
                    Item {
                        width:  itemInstance.width
                        height: itemInstance.height

                        BarComponentItem {
                            id: itemInstance
                            componentId:   modelData
                            sourceSection: section.sectionName
                            label:         barRoot.componentMetadata[modelData]?.name || modelData
                        }

                        DropArea {
                            anchors.fill: parent
                            keys: ["bar-component"]
                            onDropped: (drop) => {
                                var data = drop.source && drop.source.dragData;
                                if (!data) return;
                                barRoot.moveComponent(data.componentId, data.sourceSection, section.sectionName, index);
                                drop.accept();
                            }
                        }
                    }
                }
            }
        }
    }
}
