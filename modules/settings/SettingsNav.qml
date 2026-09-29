import QtQuick
import qs
pragma Singleton

/**
 * Keyboard navigation for settings pages and the settings menu.
 *
 * The active page (or menu) hands its root item to `bind()`. Navigation walks
 * that tree depth-first, collecting every visible, focusable SettingsRow and
 * BaseListItem in visual order, and drives Up/Down (move), Left/Right (adjust
 * the focused row's control) and Enter/Space (activate). Backspace/Escape are
 * left to the page so they can pop the StackView.
 *
 * A single shared index means only one row is highlighted at a time, and the
 * focus marker is cleared whenever the bound page changes.
 */
QtObject {
    id: root
    // The page/menu root currently bound, and the collected navigable items.
    property Item currentRoot: null
    property var items: []
    property int index: -1

    function bind(item) {
        // Transient nulls occur while a StackView swaps pages; ignore them and
        // keep the last real page bound rather than clearing the row list.
        if (item === null || item === undefined)
            return;
        if (root.currentRoot === item)
            return;
        root.clearHighlight();
        root.currentRoot = item;
        root.index = -1; // Start fresh on a new page; rebuild focuses the first row.
        root._retries = 0;
        // A StackView page is created before its children populate, so the first
        // collection can run too early; retry briefly until rows appear.
        root._deferredRebuild();
    }

    property int _retries: 0

    function _deferredRebuild() {
        Qt.callLater(function () {
            root.rebuild();
            if (root.items.length === 0 && root.currentRoot && root._retries < 30) {
                root._retries++;
                retryTimer.restart();
            }
        });
    }

    property Timer retryTimer: Timer {
        interval: 60
        repeat: false
        onTriggered: root._deferredRebuild()
    }

    function rebuild() {
        var list = [];
        if (root.currentRoot)
            root._collect(root.currentRoot, list);
        root.items = list;
        // Focus the first row on (re)build so arrow keys work immediately.
        if (list.length > 0 && root.index < 0)
            root.index = 0;
        if (root.index >= list.length)
            root.index = list.length - 1;
        root.applyHighlight();
    }

    // Depth-first collection of navigable items in child order (declaration
    // order), which matches visual order for the vertical settings layouts.
    function _collect(node, out) {
        if (!node || !node.children)
            return;
        for (var i = 0; i < node.children.length; i++) {
            var c = node.children[i];
            if (!c)
                continue;
            if (root._isNavigable(c)) {
                out.push(c);
                continue; // don't descend into a navigable item's own controls
            }
            if (c.children)
                root._collect(c, out);
        }
    }

    function _isNavigable(c) {
        if (c.focusable !== undefined)
            return c.focusable === true;
        if (c.navigable !== undefined)
            return c.navigable === true && c.visible !== false;
        return false;
    }

    function _setHighlight(item, on) {
        if (item) {
            if (item.navFocused !== undefined) item.navFocused = on;
            if (item.navHighlighted !== undefined) item.navHighlighted = on;
        }
    }

    function applyHighlight() {
        root.clearHighlight();
        if (root.index >= 0 && root.index < root.items.length)
            root._setHighlight(root.items[root.index], true);
    }

    function clearHighlight() {
        for (var i = 0; i < root.items.length; i++)
            root._setHighlight(root.items[i], false);
    }

    function move(delta) {
        if (root.items.length === 0)
            return false;
        if (root.index < 0)
            root.index = delta > 0 ? 0 : root.items.length - 1;
        else
            root.index = Math.max(0, Math.min(root.items.length - 1, root.index + delta));
        root.applyHighlight();
        return true;
    }

    function adjust(delta) {
        var item = root.items[root.index];
        if (item && typeof item.adjust === "function")
            return item.adjust(delta);
        return false;
    }

    function activate() {
        var item = root.items[root.index];
        if (!item)
            return false;
        if (typeof item.activate === "function")
            return item.activate();
        if (typeof item.onClicked === "function" || item.clicked !== undefined) {
            item.clicked();
            return true;
        }
        return false;
    }
}
