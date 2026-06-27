import QtQuick
import QtQuick.Layouts
import qs
import qs.services

BaseListItem {
    id: root

    property var itemData: null

    showInternalIndicator: false
    rightIcon: ""
    titleSize: Theme.typography.size.base
    subtitleSize: Theme.typography.size.small
    leftIconInteractive: false

    leftIcon: {
        if (!itemData) return "content_copy";
        if (itemData.isImage) return "image";
        if (Clipboard.isCode(itemData.text)) return "code";
        return "text_fields";
    }

    title: {
        if (!itemData) return "";
        if (itemData.isImage) {
            return Clipboard.getImageTitle(itemData);
        }
        var t = itemData.text || "";
        var firstLine = t.split("\n")[0];
        return firstLine.length > 0 ? firstLine : "(empty)";
    }

    subtitle: {
        if (!itemData) return "";
        var _ = Clipboard.firstSeenVersion;
        var parts = [];
        var ts = Clipboard.getFirstSeen(itemData.id);
        if (ts) {
            var ago = Clipboard.formatTimeAgo(ts);
            if (ago.length > 0) parts.push(ago);
        }
        var size = Clipboard.getSize(itemData);
        if (size) parts.push(size);
        return parts.join(" • ");
    }
}
