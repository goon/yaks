import QtQuick
import Quickshell
import Quickshell.Io
import qs
pragma Singleton

QtObject {
    id: root

    function shutdown() {
        ProcessService.runDetached(["systemctl", "poweroff"]);
    }

    function reboot() {
        ProcessService.runDetached(["systemctl", "reboot"]);
    }

    function suspend() {
        ProcessService.runDetached(["systemctl", "suspend"]);
    }

}
