import QtQuick
import Quickshell
import Quickshell.Io
import qs
pragma Singleton

QtObject {
    id: root

    readonly property bool canShutdown: true
    readonly property bool canReboot: true
    readonly property bool canSuspend: true
    readonly property bool canHibernate: true
    readonly property bool canLogout: true

    signal powerOperationStarted(string operation)

    function poweroff() {
        powerOperationStarted("poweroff");
        ProcessService.runDetached(["systemctl", "poweroff"]);
    }

    function shutdown() {
        poweroff();
    }

    function reboot() {
        powerOperationStarted("reboot");
        ProcessService.runDetached(["systemctl", "reboot"]);
    }

    function suspend() {
        powerOperationStarted("suspend");
        ProcessService.runDetached(["systemctl", "suspend"]);
    }

    function logout() {
        powerOperationStarted("logout");
        Compositor.quit();
    }

}
