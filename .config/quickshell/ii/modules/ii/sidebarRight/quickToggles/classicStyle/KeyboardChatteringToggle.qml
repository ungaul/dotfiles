import qs.modules.common.widgets
import qs.services

QuickToggleButton {
    id: root
    toggled: KeyboardChattering.active
    buttonIcon: KeyboardChattering.active ? "keyboard" : "keyboard_off"
    onClicked: {
        KeyboardChattering.toggle()
    }
    StyledToolTip {
        text: "Keyboard chattering fix"
    }
}
