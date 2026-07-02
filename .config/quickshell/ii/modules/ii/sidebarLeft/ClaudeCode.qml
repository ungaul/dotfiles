import qs
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import QtQuick
import QMLTermWidget 2.0

// Claude Code, genuinely embedded: QMLTermWidget renders a real PTY-backed
// VT100 terminal directly inside this Item (no separate window, no Hyprland
// window-rule tricks needed).
FocusScope {
    id: root

    QMLTermWidget {
        id: terminal
        anchors.fill: parent
        focus: true
        font.family: "monospace"
        font.pointSize: 11
        colorScheme: "DarkPastels"

        session: QMLTermSession {
            id: session
            initialWorkingDirectory: FileUtils.trimFileProtocol(Directories.home)
            shellProgram: "/bin/bash"
            shellProgramArgs: ["-lc", "claude"]
        }

        MouseArea {
            anchors.fill: parent
            propagateComposedEvents: true
            onPressed: (mouse) => {
                terminal.forceActiveFocus();
                mouse.accepted = false;
            }
        }

        Component.onCompleted: {
            session.startShellProgram();
            terminal.forceActiveFocus();
        }

        // QMLTermWidget only recalculates its column/row grid on an actual
        // width/height change. While the sidebar is closed its window is
        // hidden but this item's size never changes, so the terminal doesn't
        // relayout to fill it on reopen. Nudge the size to force a relayout.
        Connections {
            target: GlobalStates
            function onSidebarLeftOpenChanged() {
                if (GlobalStates.sidebarLeftOpen)
                    relayoutNudge.start();
            }
        }
        Timer {
            id: relayoutNudge
            interval: 1
            onTriggered: {
                terminal.anchors.rightMargin = 1;
                restoreMargin.start();
            }
        }
        Timer {
            id: restoreMargin
            interval: 1
            onTriggered: terminal.anchors.rightMargin = 0
        }
    }
}
