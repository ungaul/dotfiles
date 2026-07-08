import qs
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import QtQuick
import QMLTermWidget 2.0

// Claude Code, genuinely embedded: QMLTermWidget renders a real PTY-backed
// VT100 terminal directly inside this Item (no separate window, no Hyprland
// window-rule tricks needed).
//
// The terminal widget is only instantiated while the sidebar is open: a live
// VT100 emulator repaints on every byte of PTY output, which is expensive to
// keep running in the background. It's loaded inside a Loader gated on
// GlobalStates.sidebarLeftOpen so closing the sidebar destroys the widget
// (stopping that rendering cost) and reopening it recreates one, which just
// re-attaches to the same persistent tmux session - no state lost.
FocusScope {
    id: root

    Loader {
        id: terminalLoader
        anchors.fill: parent
        active: GlobalStates.sidebarLeftOpen
        sourceComponent: QMLTermWidget {
            id: terminal
            focus: true
            font.family: "monospace"
            font.pointSize: 11
            colorScheme: "DarkPastels"

            session: QMLTermSession {
                id: session
                initialWorkingDirectory: FileUtils.trimFileProtocol(Directories.home)
                shellProgram: "/bin/bash"
                // Run inside a persistent tmux session so Claude Code survives
                // this widget (and quickshell itself) being torn down: the
                // tmux server (and the claude process running inside it) is
                // an independent process tree. Reopening the sidebar
                // re-attaches to the same running session.
                shellProgramArgs: ["-lc", "tmux new-session -A -s claude-code claude"]

                // Loader destroying this item on sidebar close does not by
                // itself hang up the PTY - the wrapping bash (and the tmux
                // client attached to it) was found staying alive as an
                // orphaned child of quickshell, continuing to receive and
                // process terminal output in the background. SIGHUP here
                // makes tmux detach the client (its normal behavior on
                // terminal hangup) rather than leaving it running.
                Component.onDestruction: sendSignal(1)
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
        }
    }
}
