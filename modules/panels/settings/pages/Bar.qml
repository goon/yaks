import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs

SettingsPage {
    id: root

    title: "Bar"

    ColumnLayout {
        Layout.fillWidth: true
        spacing: Theme.geometry.spacing.medium

        GridLayout {
            columns: 2
            rowSpacing: Theme.geometry.spacing.dynamicPadding
            columnSpacing: Theme.geometry.spacing.dynamicPadding
            Layout.fillWidth: true

            BaseText {
                text: "Configure the position, size, and layout of the system bar."
                color: Theme.colors.text
                pixelSize: Theme.typography.size.medium
                Layout.fillWidth: true
                Layout.preferredWidth: 0
                Layout.columnSpan: 2
                Layout.bottomMargin: Theme.geometry.spacing.small
            }

            // ── Bar Dimensions ──────────────────────────────────────────
            BaseText {
                text: "Bar Dimensions"
                weight: Theme.typography.weights.bold
                color: Theme.colors.primary
                pixelSize: Theme.typography.size.large
                Layout.columnSpan: 2
            }

            BaseText {
                text: "Position:"
                pixelSize: Theme.typography.size.medium
            }

            BaseComboBox {
                Layout.fillWidth: true
                textRole: "label"
                model: [{ "label": "Top", "value": "top" }, { "label": "Bottom", "value": "bottom" }]
                currentIndex: {
                    for (var i = 0; i < model.length; i++) {
                        if (model[i].value === Preferences.barPosition)
                            return i;
                    }
                    return -1;
                }
                onActivated: (index) => {
                    Preferences.barPosition = model[index].value;
                }
            }

            BaseText {
                text: "Fit to Content:"
                pixelSize: Theme.typography.size.medium
            }

            BaseSwitch {
                Layout.alignment: Qt.AlignLeft
                checked: Preferences.barFitToContent
                onToggled: {
                    if (checked) {
                        let left   = Array.from(Preferences.barLeftComponents);
                        let center = Array.from(Preferences.barCenterComponents);
                        let right  = Array.from(Preferences.barRightComponents);
                        let combined = center.concat(left, right);
                        Preferences.barCenterComponents = combined;
                        Preferences.barLeftComponents   = [];
                        Preferences.barRightComponents  = [];
                    }
                    Preferences.barFitToContent = checked;
                }
            }

            BaseText {
                text: "Bar Density:"
                pixelSize: Theme.typography.size.medium
            }

            BaseComboBox {
                Layout.fillWidth: true
                textRole: "label"
                model: [
                    { "label": "Compact",     "value": 0 },
                    { "label": "Default",     "value": 1 },
                    { "label": "Comfortable", "value": 2 }
                ]
                currentIndex: {
                    for (var i = 0; i < model.length; i++) {
                        if (model[i].value === Preferences.barDensity)
                            return i;
                    }
                    return 1;
                }
                onActivated: (index) => {
                    Preferences.barDensity = model[index].value;
                }
            }

            BaseText {
                text: "Top Margin:"
                pixelSize: Theme.typography.size.medium
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: Theme.geometry.spacing.large

                BaseSlider {
                    id: barTopMarginSlider
                    Layout.fillWidth: true
                    from: 0; to: 50; stepSize: 1
                    value: Preferences.barMarginTop
                    onMoved: Preferences.barMarginTop = value
                }

                BaseText {
                    text: Math.round(barTopMarginSlider.value) + "px"
                    Layout.preferredWidth: 40
                    horizontalAlignment: Text.AlignRight
                }
            }

            BaseText {
                text: "Side Margin:"
                pixelSize: Theme.typography.size.medium
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: Theme.geometry.spacing.large

                BaseSlider {
                    id: barSideMarginSlider
                    Layout.fillWidth: true
                    from: 0; to: 50; stepSize: 1
                    value: Preferences.barMarginSide
                    onMoved: Preferences.barMarginSide = value
                }

                BaseText {
                    text: Math.round(barSideMarginSlider.value) + "px"
                    Layout.preferredWidth: 40
                    horizontalAlignment: Text.AlignRight
                }
            }

            // ── Bar Components ───────────────────────────────────────────
            BaseText {
                text: "Bar Components"
                weight: Theme.typography.weights.bold
                color: Theme.colors.primary
                pixelSize: Theme.typography.size.large
                Layout.columnSpan: 2
                Layout.topMargin: Theme.geometry.spacing.large
            }

            BaseText {
                text: "Customize the layout and elements of your system bar."
                color: Theme.colors.text
                pixelSize: Theme.typography.size.medium
                Layout.fillWidth: true
                Layout.preferredWidth: 0
                Layout.columnSpan: 2
                Layout.bottomMargin: Theme.geometry.spacing.small
            }


            BarConfiguration {
                Layout.columnSpan: 2
                Layout.fillWidth: true
            }

        }
    }

    // ── BarConfiguration component ───────────────────────────────────────
    component BarConfiguration: ColumnLayout {
        id: barRoot

        readonly property var componentMetadata: ({
            "workspaces": { name: "Workspaces", icon: "view_week" },
            "clock":      { name: "Clock",      icon: "schedule"  },
            "dock":       { name: "Dock",        icon: "vertical_split" },
            "indicators": { name: "Indicators",  icon: "stacks"   },
        })

        readonly property var allComponents: Object.keys(componentMetadata)

        function getAvailableComponents() {
            var used = Preferences.barLeftComponents.concat(
                Preferences.barCenterComponents,
                Preferences.barRightComponents
            );
            return allComponents.filter(function(id) { return !used.includes(id); });
        }

        function addComponent(componentId, targetSection) {
            var list = getList(targetSection);
            if (list.includes(componentId)) return;
            list.push(componentId);
            updateList(targetSection, list);
        }

        function removeComponent(listName, index) {
            var list = getList(listName);
            list.splice(index, 1);
            updateList(listName, list);
        }

        function getList(listName) {
            if (listName === "barLeftComponents")   return Array.from(Preferences.barLeftComponents);
            if (listName === "barCenterComponents") return Array.from(Preferences.barCenterComponents);
            if (listName === "barRightComponents")  return Array.from(Preferences.barRightComponents);
            return [];
        }

        function updateList(listName, list) {
            if (listName === "barLeftComponents")        Preferences.barLeftComponents   = list;
            else if (listName === "barCenterComponents") Preferences.barCenterComponents = list;
            else if (listName === "barRightComponents")  Preferences.barRightComponents  = list;
        }

        function moveComponent(componentId, sourceSection, targetSection, targetIndex) {
            if (sourceSection === targetSection && targetSection === "available") return;

            if (sourceSection !== "available") {
                var sourceList  = getList(sourceSection);
                var sourceIndex = sourceList.indexOf(componentId);
                if (sourceIndex > -1) {
                    sourceList.splice(sourceIndex, 1);
                    updateList(sourceSection, sourceList);
                }
            }

            if (targetSection !== "available") {
                var targetList = getList(targetSection);
                if (targetIndex === -1 || targetIndex >= targetList.length) {
                    targetList.push(componentId);
                } else {
                    targetList.splice(targetIndex, 0, componentId);
                }
                updateList(targetSection, targetList);
            }
        }

        property color primaryColor: Theme.colors.primary
        Layout.fillWidth: true

        ColumnLayout {
            Layout.fillWidth: true
            spacing: Theme.geometry.spacing.medium

            // Available Components
            ColumnLayout {
                Layout.fillWidth: true
                visible: getAvailableComponents().length > 0 || dropAreaAvailable.containsDrag

                BaseText { text: "Available Components"; color: Theme.colors.muted; font.weight: Font.Medium }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: availableFlow.height + Theme.geometry.spacing.small * 2
                    color: dropAreaAvailable.containsDrag ? Theme.alpha(barRoot.primaryColor, 0.1) : Theme.colors.transparent
                    radius: Theme.geometry.radius
                    border.width: 1
                    border.color: dropAreaAvailable.containsDrag ? Theme.colors.primary : Theme.colors.transparent

                    DropArea {
                        id: dropAreaAvailable
                        anchors.fill: parent
                        keys: ["bar-component"]
                        onDropped: (drop) => {
                            var data = drop.source && drop.source.dragData;
                            if (!data) return;
                            barRoot.moveComponent(data.componentId, data.sourceSection, "available", -1);
                            drop.accept();
                        }
                    }

                    Flow {
                        id: availableFlow
                        anchors.centerIn: parent
                        width: parent.width
                        spacing: Theme.geometry.spacing.small

                        Repeater {
                            model: getAvailableComponents()
                            BarComponentItem {
                                componentId: modelData
                                sourceSection: "available"
                                label: barRoot.componentMetadata[modelData]?.name || modelData
                            }
                        }
                    }
                }
            }

            BaseSeparator { Layout.fillWidth: true; visible: getAvailableComponents().length > 0 }

            ComponentList {
                Layout.fillWidth: true
                sectionName: "barLeftComponents"
                sectionTitle: "Left"
                components: Preferences.barLeftComponents
                visible: !Preferences.barFitToContent
            }

            BaseSeparator { Layout.fillWidth: true; visible: !Preferences.barFitToContent }

            ComponentList {
                Layout.fillWidth: true
                sectionName: "barCenterComponents"
                sectionTitle: "Center"
                components: Preferences.barCenterComponents
            }

            BaseSeparator { Layout.fillWidth: true; visible: !Preferences.barFitToContent }

            ComponentList {
                Layout.fillWidth: true
                sectionName: "barRightComponents"
                sectionTitle: "Right"
                components: Preferences.barRightComponents
                visible: !Preferences.barFitToContent
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

            width:  innerLayout.width  + Theme.geometry.spacing.medium * 2
            height: Theme.dimensions.iconBase + Theme.geometry.spacing.small  * 2

            // Base radius
            radius: Theme.geometry.radius

            // Outer border/color for inactive available components
            color:        Theme.colors.transparent
            border.width: sourceSection === "available" ? 1 : 0
            border.color: Theme.colors.border

            // Premium gradient layer (visible for active sections OR when hovered/dragged)
            Rectangle {
                anchors.fill: parent
                radius: parent.radius
                visible: (sourceSection !== "available") || rect.isActive
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0.0; color: Theme.colors.primary }
                    GradientStop { position: 1.0; color: Theme.colors.secondary }
                }
            }

            // Cutout/Inner background layer
            // This is visible when not hovered/dragged for active components, to show the cutout gradient border.
            // For available (inactive) components, it is hidden to keep the background transparent.
            Rectangle {
                anchors.fill: parent
                anchors.margins: 1.5
                radius: parent.radius - anchors.margins
                visible: !rect.isActive && sourceSection !== "available"
                color: Theme.colors.surface

                // Overlay primary tint for premium active section items
                Rectangle {
                    anchors.fill: parent
                    radius: parent.radius
                    visible: sourceSection !== "available"
                    color: Qt.alpha(Theme.colors.primary, 0.08)
                }
            }

            // Drag handler covering the entire background of the pill
            MouseArea {
                id: dragHandler
                anchors.fill: parent
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                drag.target: rect
                drag.axis:   Drag.XAndYAxis
                cursorShape: drag.active ? Qt.ClosedHandCursor : Qt.OpenHandCursor

                onReleased: { rect.Drag.drop(); rect.x = 0; rect.y = 0; }

                onClicked: (mouse) => {
                    if (mouse.button === Qt.RightButton && sourceSection !== "available") {
                        var list = barRoot.getList(sourceSection);
                        var idx  = list.indexOf(componentId);
                        if (idx > -1) barRoot.removeComponent(sourceSection, idx);
                    }
                }
            }

            Row {
                id: innerLayout
                anchors.centerIn: parent
                spacing: 6

                BaseIcon {
                    icon:  barRoot.componentMetadata[itemRoot.componentId]?.icon || "extension"
                    size:  Theme.dimensions.iconBase
                    color: rect.isActive ? Theme.colors.background : (sourceSection !== "available" ? Theme.colors.primary : Theme.colors.text)
                    anchors.verticalCenter: parent.verticalCenter
                }

                BaseText {
                    text:  itemRoot.label
                    color: rect.isActive ? Theme.colors.background : (sourceSection !== "available" ? Theme.colors.textLighter : Theme.colors.text)
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
        required property string sectionTitle
        required property var    components

        spacing: Theme.geometry.spacing.small

        BaseText { text: sectionTitle; color: Theme.colors.muted; font.weight: Font.Medium }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: Math.max(flow.height, 50)
            color:        dropArea.containsDrag ? Theme.alpha(barRoot.primaryColor, 0.1) : Theme.colors.transparent
            radius:       Theme.geometry.radius
            border.width: 1
            border.color: dropArea.containsDrag ? Theme.colors.primary : Theme.colors.transparent

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

            BaseText {
                visible: section.components.length === 0 && !dropArea.containsDrag
                anchors.centerIn: parent
                text:    "Drop components here"
                color:   Theme.colors.muted
                font.italic: true
                padding: 4
            }

            Flow {
                id: flow
                anchors.top:   parent.top
                anchors.left:  parent.left
                anchors.right: parent.right
                anchors.margins: 4
                spacing: Theme.geometry.spacing.small

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
