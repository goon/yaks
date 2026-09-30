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

    // Containers currently watched for child additions. Kept so they can be
    // disconnected when a different page is bound.
    property var _watched: []

    function bind(item) {
        // Transient nulls occur while a StackView swaps pages; ignore them and
        // keep the last real page bound rather than clearing the row list.
        if (item === null || item === undefined)
            return;
        if (root.currentRoot === item)
            return;
        root.clearHighlight();
        root._unwatchAll();
        root.currentRoot = item;
        root.index = -1; // Start fresh on a new page; rebuild focuses the first row.
        // A StackView page exists before its rows populate, so collect now and
        // again whenever a watched container gains children. This is event-based
        // rather than a retry timer, and self-heals for lazily-added rows.
        root._watchContainers(item);
        Qt.callLater(root.rebuild);
    }

    // Attach a childrenChanged watcher to every container under `node` (the page
    // root and each layout/group), so appearing rows trigger a rebuild. Stops
    // descending at navigable items, since we never descend into them anyway.
    function _watchContainers(node) {
        if (!node || !node.children)
            return;
        root._watch(node);
        for (var i = 0; i < node.children.length; i++) {
            var c = node.children[i];
            if (!c || root._isNavigable(c))
                continue;
            root._watchContainers(c);
        }
    }

    function _watch(container) {
        for (var i = 0; i < root._watched.length; i++)
            if (root._watched[i].container === container)
                return;
        var handler = function () { root._onChildrenChanged(); };
        container.childrenChanged.connect(handler);
        root._watched = root._watched.concat([{ container: container, handler: handler }]);
    }

    // Watched containers can already be destroyed when we get here (popping a
    // StackView page tears down its item tree), and a destroyed QML object is
    // still truthy in JS while its signals are gone — so `disconnect` on it
    // throws. Clear the list first so a throw can never strand entries, and
    // tolerate a dead container rather than letting it abort the caller's bind.
    function _unwatchAll() {
        var watched = root._watched;
        root._watched = [];
        for (var i = 0; i < watched.length; i++) {
            var w = watched[i];
            try {
                if (w.container && w.handler)
                    w.container.childrenChanged.disconnect(w.handler);
            } catch (e) { /* already destroyed; nothing left to disconnect */ }
        }
    }

    // A watched container gained a child: recollect, which also picks up any new
    // container that itself needs watching.
    function _onChildrenChanged() {
        root.rebuild();
    }

    function rebuild() {
        // Re-arm watchers: containers that appeared since the last pass (e.g. a
        // lazily-built group) need watching so their later rows trigger a rebuild.
        if (root.currentRoot)
            root._watchContainers(root.currentRoot);

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

    // Hand control back to the pointer: drop the keyboard selection so hover
    // drives the indicator again. Called when the mouse moves over the surface.
    function releaseFocus() {
        if (root.index === -1)
            return;
        root.clearHighlight();
        root.index = -1;
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
