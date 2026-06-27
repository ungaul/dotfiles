import qs
import qs.services
import QtQuick
import Quickshell
import qs.modules.ii.onScreenDisplay

OsdValueIndicator {
    value: GlobalStates.keyboardChatteringActive ? 1.0 : 0.0
    icon: GlobalStates.keyboardChatteringActive ? "keyboard" : "keyboard_off"
    name: GlobalStates.keyboardChatteringActive ? "KB fix ON" : "KB fix OFF"
    from: 0
    to: 1

    onValueChanged: {
        if (GlobalStates.keyboardChatteringActive) {
            Quickshell.execDetached(["systemctl", "--user", "start", "keyboard-chattering-fix"])
        } else {
            Quickshell.execDetached(["systemctl", "--user", "stop", "keyboard-chattering-fix"])
        }
    }
}
