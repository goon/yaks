import QtQuick
import Quickshell
import Quickshell.Io
import qs
pragma Singleton

QtObject {
    id: root

    function poweroff() {
        ProcessService.runDetached(["systemctl", "poweroff"]);
    }

    function shutdown() {
        poweroff();
    }

    function reboot() {
        ProcessService.runDetached(["systemctl", "reboot"]);
    }

    function suspend() {
        ProcessService.runDetached(["systemctl", "suspend"]);
    }

    function logout() {
        Compositor.quit();
    }

}
