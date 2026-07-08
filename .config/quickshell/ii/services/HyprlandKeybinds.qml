pragma Singleton
pragma ComponentBehavior: Bound

import qs.modules.common
import qs.modules.common.functions
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

/**
 * Fetches keybinds at runtime via `hyprctl binds -j`, converts them to
 * the structured format expected by CheatsheetKeybinds.qml.
 */
Singleton {
    id: root
    property string keybindParserPath: FileUtils.trimFileProtocol(`${Directories.scriptPath}/hyprland/get_keybinds.py`)
    property var keybinds: ({ children: [{ children: [] }, { children: [] }] })

    Connections {
        target: Hyprland

        function onRawEvent(event) {
            if (event.name == "configreloaded") {
                getKeybinds.running = true
            }
        }
    }

    Process {
        id: getKeybinds
        running: true
        command: ["python3", root.keybindParserPath]

        stdout: SplitParser {
            onRead: data => {
                try {
                    root.keybinds = JSON.parse(data)
                } catch (e) {
                    console.error("[HyprlandKeybinds] Error parsing keybinds:", e)
                }
            }
        }
        stderr: SplitParser {
            onRead: data => console.error("[HyprlandKeybinds] stderr:", data)
        }
        onExited: (code, status) => console.log("[HyprlandKeybinds] exited code:", code, "status:", status)
    }
}
