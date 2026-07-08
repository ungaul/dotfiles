import qs
import qs.services
import QtQuick
import Quickshell
import qs.modules.ii.onScreenDisplay

OsdValueIndicator {
    value: KeyboardChattering.active ? 1.0 : 0.0
    icon: KeyboardChattering.active ? "keyboard" : "keyboard_off"
    name: KeyboardChattering.active ? "KB fix ON" : "KB fix OFF"
    isToggle: true
    from: 0
    to: 1
}
