import QtQuick
import Quickshell
import qs.services
pragma Singleton

Singleton {
    id: root

    function toggle() {
        IslandService.togglePanel("overview");
    }

    function openOverview() {
        IslandService.openPanel("overview");
    }

    function closeOverview() {
        if (IslandService.activePanelName === "overview") {
            IslandService.closeAll();
        }
    }
}