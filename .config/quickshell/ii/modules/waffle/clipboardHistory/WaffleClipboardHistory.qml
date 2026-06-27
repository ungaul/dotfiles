import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets

Scope {
    id: root

    Connections {
        target: GlobalStates

        function onClipboardHistoryOpenChanged() {
            if (GlobalStates.clipboardHistoryOpen) {
                Cliphist.refresh();
                panelLoader.active = true;
            }
        }
    }

    Loader {
        id: panelLoader
        active: GlobalStates.clipboardHistoryOpen
        sourceComponent: PanelWindow {
            id: panelWindow
            exclusiveZone: 0
            WlrLayershell.namespace: "quickshell:clipboardHistory"
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
            color: "transparent"

            anchors {
                bottom: Config.options.waffles.bar.bottom
                top: !Config.options.waffles.bar.bottom
                right: true
            }

            implicitWidth: content.implicitWidth
            implicitHeight: content.implicitHeight

            HyprlandFocusGrab {
                id: focusGrab
                active: true
                windows: [panelWindow]
                onCleared: content.close()
            }

            Connections {
                target: GlobalStates
                function onClipboardHistoryOpenChanged() {
                    if (!GlobalStates.clipboardHistoryOpen)
                        content.close();
                }
            }

            ClipboardHistoryContent {
                id: content
                anchors.fill: parent

                onClosed: {
                    GlobalStates.clipboardHistoryOpen = false;
                    panelLoader.active = false;
                }
            }
        }
    }

    function toggleOpen() {
        GlobalStates.clipboardHistoryOpen = !GlobalStates.clipboardHistoryOpen;
    }

    IpcHandler {
        target: "clipboardHistory"

        function toggle() {
            root.toggleOpen();
        }
    }

    GlobalShortcut {
        name: "clipboardHistoryToggle"
        description: "Toggles the Waffle clipboard history popup on press"

        onPressed: root.toggleOpen()
    }
}
