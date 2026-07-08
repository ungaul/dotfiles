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

        function onResourceMonitorOpenChanged() {
            if (GlobalStates.resourceMonitorOpen)
                panelLoader.active = true;
        }
    }

    Loader {
        id: panelLoader
        active: GlobalStates.resourceMonitorOpen
        sourceComponent: PanelWindow {
            id: panelWindow
            exclusiveZone: 0
            WlrLayershell.namespace: "quickshell:resourceMonitor"
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
            color: "transparent"

            anchors {
                bottom: Config.options.waffles.bar.bottom
                top: !Config.options.waffles.bar.bottom
                left: true
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
                function onResourceMonitorOpenChanged() {
                    if (!GlobalStates.resourceMonitorOpen)
                        content.close();
                }
            }

            ResourceMonitorContent {
                id: content
                anchors.fill: parent

                onClosed: {
                    GlobalStates.resourceMonitorOpen = false;
                    panelLoader.active = false;
                }
            }
        }
    }

    function toggleOpen() {
        GlobalStates.resourceMonitorOpen = !GlobalStates.resourceMonitorOpen;
    }

    IpcHandler {
        target: "resourceMonitor"

        function toggle() {
            root.toggleOpen();
        }
    }

    GlobalShortcut {
        name: "resourceMonitorToggle"
        description: "Toggles the Waffle resource monitor on press"

        onPressed: root.toggleOpen()
    }
}
