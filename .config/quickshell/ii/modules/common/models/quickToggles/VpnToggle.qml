import QtQuick
import Quickshell
import Quickshell.Io
import qs.modules.common

QuickToggleModel {
    id: root
    name: "VPN"
    icon: "vpn_lock"
    toggled: false
    hasMenu: true
    statusText: toggled ? vpnName : "Off"
    tooltipText: "VPN | Right-click to manage"

    property string vpnName: ""

    Timer {
        interval: 5000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            stateProc.running = false
            stateProc.running = true
        }
    }

    Process {
        id: stateProc
        command: ["bash", "-c",
            "nmcli -t -f NAME,TYPE,STATE con show --active | awk -F: '$2==\"vpn\" || $2==\"wireguard\"{print $1; found=1} END{if(!found) print \"\"}'"
        ]
        stdout: SplitParser {
            onRead: data => {
                const name = data.trim()
                root.vpnName = name
                root.toggled = name !== ""
            }
        }
    }

    Process {
        id: connectProc
        command: ["bash", "-c",
            "nmcli -t -f NAME,TYPE con show | awk -F: '$2==\"vpn\" || $2==\"wireguard\"{print $1; exit}' | xargs -I{} nmcli con up \"{}\""
        ]
        onExited: { stateProc.running = false; stateProc.running = true }
    }

    Process {
        id: disconnectProc
        command: ["bash", "-c",
            "nmcli -t -f NAME,TYPE,STATE con show --active | awk -F: '($2==\"vpn\" || $2==\"wireguard\") && $3==\"activated\"{print $1}' | xargs -I{} nmcli con down \"{}\""
        ]
        onExited: { stateProc.running = false; stateProc.running = true }
    }

    mainAction: () => {
        if (root.toggled) {
            disconnectProc.running = false
            disconnectProc.running = true
        } else {
            connectProc.running = false
            connectProc.running = true
        }
    }
}
