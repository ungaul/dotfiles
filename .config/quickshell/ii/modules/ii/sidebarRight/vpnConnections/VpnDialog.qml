import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

WindowDialog {
    id: root
    backgroundHeight: 400

    property bool loading: true

    ListModel {
        id: vpnModel
    }

    Process {
        id: listProc
        command: ["bash", "-c",
            "nmcli -t -f NAME,TYPE,STATE con show | awk -F: '$2==\"vpn\" || $2==\"wireguard\"{print $1 \":\" $3}'"
        ]
        stdout: SplitParser {
            onRead: data => {
                const parts = data.trim().split(":")
                if (parts.length >= 2) {
                    const name = parts[0]
                    const state = parts.slice(1).join(":")
                    vpnModel.append({ name: name, active: state === "activated" })
                }
            }
        }
        onExited: root.loading = false
    }

    Process {
        id: actionProc
        property string connectionName: ""
        property bool connecting: false
        command: connecting
            ? ["nmcli", "con", "up", connectionName]
            : ["nmcli", "con", "down", connectionName]
        onExited: {
            vpnModel.clear()
            root.loading = true
            listProc.running = false
            listProc.running = true
        }
    }

    Component.onCompleted: listProc.running = true

    WindowDialogTitle {
        text: "VPN Connections"
    }

    WindowDialogSeparator {}

    StyledIndeterminateProgressBar {
        visible: root.loading && vpnModel.count === 0
        Layout.fillWidth: true
        Layout.topMargin: -8
        Layout.bottomMargin: -8
        Layout.leftMargin: -Appearance.rounding.large
        Layout.rightMargin: -Appearance.rounding.large
    }

    ListView {
        Layout.fillHeight: true
        Layout.fillWidth: true
        Layout.topMargin: -15
        Layout.bottomMargin: -16
        Layout.leftMargin: -Appearance.rounding.large
        Layout.rightMargin: -Appearance.rounding.large
        clip: true
        spacing: 0
        model: vpnModel

        delegate: Item {
            required property string name
            required property bool active
            required property int index
            width: ListView.view.width
            implicitHeight: row.implicitHeight + 16

            Rectangle {
                anchors.fill: parent
                color: active ? Appearance.colors.colPrimary : "transparent"
                opacity: 0.08
            }

            RowLayout {
                id: row
                anchors {
                    left: parent.left
                    right: parent.right
                    verticalCenter: parent.verticalCenter
                    leftMargin: Appearance.rounding.large
                    rightMargin: Appearance.rounding.large
                }
                spacing: 12

                MaterialSymbol {
                    text: active ? "vpn_lock" : "vpn_key_off"
                    iconSize: Appearance.font.pixelSize.larger
                    color: active ? Appearance.colors.colPrimary : Appearance.colors.colOnLayer0
                }

                StyledText {
                    Layout.fillWidth: true
                    text: name
                    font.pixelSize: Appearance.font.pixelSize.normal
                    color: Appearance.colors.colOnLayer0
                }

                StyledText {
                    text: active ? "Connected" : "Off"
                    font.pixelSize: Appearance.font.pixelSize.small
                    color: active ? Appearance.colors.colPrimary : Appearance.colors.colOnLayer1
                }

                DialogButton {
                    buttonText: active ? "Disconnect" : "Connect"
                    onClicked: {
                        actionProc.connectionName = name
                        actionProc.connecting = !active
                        actionProc.running = false
                        actionProc.running = true
                    }
                }
            }
        }

        StyledText {
            anchors.centerIn: parent
            visible: !root.loading && vpnModel.count === 0
            text: "No VPN connections found"
            color: Appearance.colors.colOnLayer1
            font.pixelSize: Appearance.font.pixelSize.normal
        }
    }

    WindowDialogSeparator {}

    WindowDialogButtonRow {
        Layout.fillWidth: true

        Item { Layout.fillWidth: true }

        DialogButton {
            buttonText: "Done"
            onClicked: root.dismiss()
        }
    }
}
