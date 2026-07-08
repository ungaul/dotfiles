pragma Singleton
import qs.modules.common
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property bool active: false

    Connections {
        target: Persistent
        function onReadyChanged() {
            if (!Persistent.isNewHyprlandInstance) {
                root.apply(Persistent.states.keyboard.chatteringMitigation);
            } else {
                Persistent.states.keyboard.chatteringMitigation = false;
            }
        }
    }

    function apply(active) {
        root.active = active;
        if (active) {
            Quickshell.execDetached(["systemctl", "--user", "start", "keyboard-chattering-fix"]);
        } else {
            Quickshell.execDetached(["systemctl", "--user", "stop", "keyboard-chattering-fix"]);
        }
    }

    function toggle(active = null) {
        const newActive = active !== null ? active : !root.active;
        Persistent.states.keyboard.chatteringMitigation = newActive;
        root.apply(newActive);
    }
}
