import QtQuick
import Quickshell
import Quickshell.Io
import qs
pragma Singleton

QtObject {
    id: root

    function shutdown() {
        Runner.runDetached(["systemctl", "poweroff"]);
    }

    function reboot() {
        Runner.runDetached(["systemctl", "reboot"]);
    }

    function suspend() {
        Runner.runDetached(["systemctl", "suspend"]);
    }

}
