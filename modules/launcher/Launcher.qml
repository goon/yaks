import QtQuick
import QtQuick.Layouts
import Quickshell
import qs

FocusScope {
    id: root

    property string moduleState: "Closed"

    readonly property int itemHeight: 54 * Globals.shellScale

    implicitWidth: 400
    implicitHeight: {
        var searchHeight = searchBar.implicitHeight;
        var padLarge = Globals.geometry.spacing.sm;

        var visibleItems = Math.min(cachedModel.length, 6);

        if (visibleItems === 0) {
            return searchHeight + padLarge;
        }

        var listHeight = (visibleItems * itemHeight) + (Math.max(0, visibleItems - 1) * padLarge);
        return searchHeight + (2 * padLarge) + 1 + listHeight;
    }

    property Item initialFocusItem: searchBar

    // ── SEARCH & MODEL STATE ──────────────────────────────────────────
    property string searchText: searchBar.text
    property var cachedModel: []
    property string _lastQuery: ""

    onSearchTextChanged: searchDebounceTimer.restart()

    function performSearch() {
        var query = searchText.trim();
        var queryChanged = query !== _lastQuery;
        _lastQuery = query;

        cachedModel = Launcher.searchApps(query, DesktopEntries.applications.values, 100);
        updateCurrentIndex(queryChanged);
    }

    function updateCurrentIndex(queryChanged) {
        if (queryChanged || appListView.currentIndex === -1) {
            if (cachedModel.length > 0)
                appListView.currentIndex = 0;
            else
                appListView.currentIndex = -1;
        }
    }

    function activateCurrentItem() {
        searchDebounceTimer.stop();
        performSearch();

        if (appListView.currentIndex < 0 && cachedModel.length > 0)
            appListView.currentIndex = 0;

        if (appListView.currentIndex >= 0 && appListView.currentIndex < cachedModel.length) {
            Launcher.executeItem(cachedModel[appListView.currentIndex]);
            Modules.closeAll();
        }
    }

    function opening() {
        Launcher.resetInputStates();
        Launcher.lastInputMethod = "keyboard";
        searchBar.text = "";
        performSearch();
    }

    function closing() {
        searchBar.text = "";
    }

    function getCurrentListView() {
        return appListView;
    }

    function navigateDown() {
        var listView = getCurrentListView();
        if (listView && listView.count > 0) {
            Launcher.resetInputStates();
            listView.forceActiveFocus();
            if (listView.currentIndex === -1)
                listView.currentIndex = 0;
            else
                listView.incrementCurrentIndex();
        }
    }

    function navigateUp() {
        var listView = getCurrentListView();
        if (listView) {
            if (listView.currentIndex > 0) {
                Launcher.resetInputStates();
                listView.decrementCurrentIndex();
            } else {
                backToSearch("");
            }
        }
    }

    function backToSearch(text) {
        Launcher.resetInputStates();
        searchBar.focusInput();
        if (text === "\b") {
            if (searchBar.text.length > 0)
                searchBar.text = searchBar.text.substring(0, searchBar.text.length - 1);
        } else if (text && text.length > 0) {
            searchBar.text += text;
        }
    }

    function handleListMouseMove(listView, index, mouse) {
        var globalPos = listView.mapToGlobal(mouse.x, mouse.y);
        if (Launcher.handleMouseMove(globalPos.x, globalPos.y))
            listView.currentIndex = index;
    }

    Connections {
        target: DesktopEntries.applications
        function onValuesChanged() {
            root.performSearch();
        }
    }

    Timer {
        id: searchDebounceTimer
        interval: 100
        repeat: false
        onTriggered: root.performSearch()
    }

    Keys.onPressed: (event) => Binds.handleKey(event)

    anchors.fill: parent
    focus: true

    ColumnLayout {
        anchors.fill: parent
        spacing: Globals.geometry.spacing.md

        BaseSearch {
            id: searchBar
            counterText: cachedModel.length > 0
                ? (appListView.currentIndex + 1) + "/" + cachedModel.length
                : ""
        }

        BaseSeparator {
            Layout.fillWidth: true
            visible: cachedModel.length > 0
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: cachedModel.length > 0
            clip: true

            ListView {
                id: appListView
                anchors.fill: parent
                spacing: Globals.geometry.spacing.sm
                activeFocusOnTab: false
                highlightMoveDuration: 0
                highlightResizeDuration: 0
                model: root.cachedModel

                onCountChanged: {
                    if (Launcher.lastInputMethod === "keyboard" || currentIndex === -1) {
                        if (count > 0 && currentIndex < 0)
                            currentIndex = 0;
                        else if (count === 0)
                            currentIndex = -1;
                    }
                }

                delegate: LauncherItemDelegate {
                    itemHeight: root.itemHeight

                    onClicked: (idx) => {
                        appListView.currentIndex = idx;
                        root.activateCurrentItem();
                    }

                    onMouseMoved: (idx, mouse) => root.handleListMouseMove(appListView, idx, mouse)
                }
            }
        }
    }

    component LauncherItemDelegate: Item {
        id: delegateRoot

        readonly property int _staggerStepMs: 30
        readonly property int _staggerCapMs: 300

        // ── MODEL ─────────────────────────────────────────────────────
        required property int index
        required property var modelData

        // ── API ───────────────────────────────────────────────────────
        required property int itemHeight
        property color iconColor: Globals.colors.text

        readonly property bool selected: ListView.view ? ListView.view.currentIndex === index : false
        readonly property string entryName: modelData ? modelData.name : ""
        readonly property string entryImage: modelData ? Launcher.resolveIcon(modelData.icon) : ""
        readonly property bool showFallbackIcon: entryImage === ""
        readonly property string fallbackText: entryName.length > 0 ? entryName.charAt(0).toUpperCase() : "?"

        signal clicked(int index)
        signal mouseMoved(int index, var mouse)

        width: ListView.view ? ListView.view.width : parent.width
        height: itemHeight

        opacity: 0
        transform: Translate { id: entryTranslate; y: 20 }

        Component.onCompleted: {
            entryAnim.start();
        }

        ParallelAnimation {
            id: entryAnim
            BaseMotion { target: delegateRoot; property: "opacity"; to: 1; delay: Math.max(0, Math.min(delegateRoot.index * delegateRoot._staggerStepMs, delegateRoot._staggerCapMs)) }
            BaseMotion { target: entryTranslate; property: "y"; to: 0; delay: Math.max(0, Math.min(delegateRoot.index * delegateRoot._staggerStepMs, delegateRoot._staggerCapMs)); easing.type: Globals.motion.easeSpring }
        }

        Rectangle {
            anchors.fill: parent
            radius: Globals.innerRadius(Globals.geometry.spacing.sm)
            color: "transparent"

            Rectangle {
                // Same tile as the Wi-Fi / Bluetooth device rows: a light wash
                // over the row, faded in on hover.
                anchors.fill: parent
                radius: Globals.innerRadius(Globals.geometry.spacing.sm)
                color: Globals.colors.hover
                opacity: mouseArea.containsMouse || delegateRoot.selected ? 1 : 0
                Behavior on opacity { BaseMotion { duration: Globals.motion.hover } }
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: Globals.geometry.spacing.xl
                anchors.rightMargin: Globals.geometry.spacing.xl
                spacing: Globals.geometry.spacing.md

                scale: mouseArea.pressed ? 0.98 : 1.0
                Behavior on scale { BaseMotion { } }

                Item {
                    Layout.preferredWidth: Globals.dimensions.thumbnail
                    Layout.preferredHeight: Globals.dimensions.thumbnail
                    Layout.alignment: Qt.AlignVCenter

                    Image {
                        anchors.fill: parent
                        source: delegateRoot.entryImage
                        asynchronous: false
                        fillMode: Image.PreserveAspectFit
                        sourceSize.width: Globals.dimensions.thumbnail
                        sourceSize.height: Globals.dimensions.thumbnail
                        mipmap: true
                        visible: !!delegateRoot.entryImage && status === Image.Ready
                    }

                    Rectangle {
                        anchors.fill: parent
                        radius: Globals.innerRadius(Globals.geometry.spacing.xs)
                        color: Globals.colors.raised
                        visible: delegateRoot.showFallbackIcon

                        BaseText {
                            anchors.centerIn: parent
                            text: delegateRoot.fallbackText
                            color: delegateRoot.iconColor
                            pixelSize: Globals.typography.icon.md
                            weight: Globals.typography.weight.bold
                        }
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter

                    BaseText {
                        Layout.fillWidth: true
                        text: delegateRoot.entryName
                        pixelSize: Globals.typography.size.lg
                        color: Globals.colors.text
                        weight: delegateRoot.selected ? Globals.typography.weight.demi : Globals.typography.weight.normal
                        elide: Text.ElideRight
                    }
                }

                BaseIcon {
                    icon: "corner-down-left"
                    size: Globals.typography.icon.md
                    color: Globals.colors.primary
                    Layout.alignment: Qt.AlignVCenter
                    opacity: delegateRoot.selected ? 1 : 0
                    Behavior on opacity { BaseMotion { duration: Globals.motion.hover } }
                }
            }
        }

        MouseArea {
            id: mouseArea
            anchors.fill: parent
            hoverEnabled: true

            onPositionChanged: (mouse) => delegateRoot.mouseMoved(delegateRoot.index, mouse)
            onClicked: delegateRoot.clicked(delegateRoot.index)
        }
    }
}
