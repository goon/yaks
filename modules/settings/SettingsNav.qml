import QtQuick
import qs
pragma Singleton

/**
 * Keyboard navigation for settings pages and the settings menu.
 *
 * The active page (or menu) hands its root item to `bind()`. Navigation walks
 * that tree depth-first, collecting every visible, navigable BaseListItem in
 * visual order, and drives Up/Down (move), Left/Right (adjust the focused
 * row's control) and Enter/Space (activate). Backspace/Escape are left to the
 * page so they can pop the StackView.
 *
 * A single shared index means only one row is highlighted at a time, and the
 * focus marker is cleared whenever the bound page changes.
 *
 * Rows are collected on `bind()` and again whenever the host calls `rebuild()`
 * (panel open, page change). A page that adds navigable rows after it is built
 * must call `SettingsNav.rebuild()` itself.
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
        Qt.callLater(root.rebuild);
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
        return c.navigable !== undefined && c.navigable === true;
    }

    function _setHighlight(item, on) {
        if (item && item.navHighlighted !== undefined)
            item.navHighlighted = on;
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

    // Left/Right: step the focused row's control by delta. Returns true if it
    // consumed the input. Duck-typed so each Base* control can be driven without
    // coupling. BaseSegmentedControl: step currentValue through its model and
    // emit. Nothing else implements an adjust protocol, so a SpinBox or Slider
    // row is a no-op here.
    function adjust(delta) {
        var c = root._control();
        if (!c) return false;

        if (c.activated !== undefined && c.model !== undefined && c.currentValue !== undefined) {
            var n = c.model.length;
            if (n <= 0) return false;
            var cur = -1;
            for (var i = 0; i < n; i++) {
                var v = (c.valueRole !== undefined && c.model[i] && c.model[i][c.valueRole] !== undefined)
                    ? c.model[i][c.valueRole] : c.model[i];
                if (v === c.currentValue) { cur = i; break; }
            }
            if (cur < 0) cur = 0;
            var next = Math.max(0, Math.min(n - 1, cur + (delta < 0 ? -1 : 1)));
            if (next === cur) return true;
            var nv = (c.valueRole !== undefined && c.model[next] && c.model[next][c.valueRole] !== undefined)
                ? c.model[next][c.valueRole] : c.model[next];
            c.currentValue = nv;
            c.activated(next, nv);
            return true;
        }
        return false;
    }

    // Enter/Space on the focused row: toggles a switch, or fires the row click.
    function activate() {
        var item = root.items[root.index];
        if (!item)
            return false;
        var c = root._control();
        if (c && c.checked !== undefined) {
            // Prefer toggle() so a control that emits toggled (e.g. BaseSwitch)
            // reaches onToggled call sites; fall back to a checked assignment.
            if (typeof c.toggle === "function")
                c.toggle();
            else
                c.checked = !c.checked;
            return true;
        }
        if (item.clickable) {
            item.clicked();
            return true;
        }
        return false;
    }

    function _control() {
        var item = root.items[root.index];
        return item && item.control !== undefined ? item.control : null;
    }
}
