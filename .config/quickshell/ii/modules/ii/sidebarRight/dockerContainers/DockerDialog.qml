pragma ComponentBehavior: Bound

import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Layouts
import Quickshell

WindowDialog {
    id: root
    backgroundHeight: 500

    // Track which stacks are expanded: { stackName: bool }
    property var expandedStacks: ({})

    function toggleStack(name) {
        expandedStacks = Object.assign({}, expandedStacks, { [name]: !expandedStacks[name] })
    }

    Component.onCompleted: Docker.refresh()

    WindowDialogTitle {
        text: "Docker"
    }

    WindowDialogSeparator {}

    StyledIndeterminateProgressBar {
        visible: Docker.loading
        Layout.fillWidth: true
        Layout.topMargin: -8
        Layout.bottomMargin: -8
        Layout.leftMargin: -Appearance.rounding.large
        Layout.rightMargin: -Appearance.rounding.large
    }

    StyledText {
        visible: !Docker.available
        Layout.fillWidth: true
        horizontalAlignment: Text.AlignHCenter
        text: "Docker not available"
        color: Appearance.colors.colOnLayer1
    }

    // Scrollable content
    Flickable {
        visible: Docker.available
        Layout.fillHeight: true
        Layout.fillWidth: true
        Layout.topMargin: -15
        Layout.bottomMargin: -16
        Layout.leftMargin: -Appearance.rounding.large
        Layout.rightMargin: -Appearance.rounding.large
        contentHeight: listCol.implicitHeight
        clip: true

        Column {
            id: listCol
            width: parent.width
            spacing: 0

            // ── Compose stacks ─────────────────────────────────────────────
            Repeater {
                model: Docker.stacksWithContainers

                Column {
                    id: stackSection
                    required property var modelData
                    required property int index
                    width: listCol.width

                    readonly property bool expanded: root.expandedStacks[modelData.name] ?? false
                    readonly property bool running: modelData.status?.startsWith("running(") ?? false

                    // Stack header row
                    Item {
                        width: parent.width
                        implicitHeight: stackRow.implicitHeight + 14

                        Rectangle {
                            anchors.fill: parent
                            color: Appearance.colors.colPrimary
                            opacity: stackSection.running ? 0.06 : 0
                            Behavior on opacity {
                                animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.toggleStack(stackSection.modelData.name)
                        }

                        RowLayout {
                            id: stackRow
                            anchors {
                                left: parent.left; right: parent.right
                                verticalCenter: parent.verticalCenter
                                leftMargin: Appearance.rounding.large
                                rightMargin: Appearance.rounding.large
                            }
                            spacing: 10

                            // Chevron
                            MaterialSymbol {
                                text: stackSection.expanded ? "expand_more" : "chevron_right"
                                iconSize: Appearance.font.pixelSize.larger
                                color: Appearance.colors.colOnSurfaceVariant
                                Behavior on text { }
                            }

                            // Status dot
                            Rectangle {
                                width: 8; height: 8; radius: 4
                                color: stackSection.running
                                       ? Appearance.colors.colPrimary
                                       : Appearance.colors.colOnSurfaceVariant
                                Behavior on color {
                                    animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
                                }
                            }

                            MaterialSymbol {
                                text: "stacks"
                                iconSize: Appearance.font.pixelSize.larger
                                color: Appearance.colors.colOnLayer0
                                font.weight: Font.Medium
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 0
                                StyledText {
                                    Layout.fillWidth: true
                                    text: stackSection.modelData.name
                                    font.pixelSize: Appearance.font.pixelSize.normal
                                    font.weight: Font.Medium
                                    color: Appearance.colors.colOnLayer0
                                    elide: Text.ElideRight
                                }
                                StyledText {
                                    text: stackSection.modelData.status
                                    font.pixelSize: Appearance.font.pixelSize.smaller
                                    color: Appearance.colors.colOnSurfaceVariant
                                }
                            }

                            // Stack action buttons
                            DialogButton {
                                visible: !stackSection.running
                                buttonText: "Start"
                                onClicked: Docker.startStack(stackSection.modelData.name)
                            }
                            DialogButton {
                                visible: stackSection.running
                                buttonText: "Stop"
                                colEnabled: Appearance.m3colors.m3error
                                onClicked: Docker.stopStack(stackSection.modelData.name)
                            }
                            DialogButton {
                                buttonText: "Restart"
                                onClicked: Docker.restartStack(stackSection.modelData.name)
                            }
                        }
                    }

                    // Collapsible containers
                    Loader {
                        id: containersLoader
                        width: parent.width
                        active: stackSection.expanded
                        visible: active

                        sourceComponent: Column {
                            width: containersLoader.width
                            spacing: 0

                            Repeater {
                                model: stackSection.modelData.containers

                                Item {
                                    id: cItem
                                    required property var modelData
                                    width: parent.width
                                    implicitHeight: cRow.implicitHeight + 12

                                    Rectangle {
                                        anchors.fill: parent
                                        color: Appearance.colors.colPrimary
                                        opacity: cItem.modelData.state === "running" ? 0.04 : 0
                                    }

                                    RowLayout {
                                        id: cRow
                                        anchors {
                                            left: parent.left; right: parent.right
                                            verticalCenter: parent.verticalCenter
                                            leftMargin: Appearance.rounding.large + 28
                                            rightMargin: Appearance.rounding.large
                                        }
                                        spacing: 8

                                        Rectangle {
                                            width: 6; height: 6; radius: 3
                                            color: cItem.modelData.state === "running"  ? Appearance.colors.colPrimary
                                                 : cItem.modelData.state === "paused"   ? Appearance.m3colors.m3secondary
                                                 : cItem.modelData.state === "exited"   ? Appearance.colors.colOnSurfaceVariant
                                                 :                                         Appearance.m3colors.m3error
                                        }

                                        MaterialSymbol {
                                            text: "deployed_code"
                                            iconSize: Appearance.font.pixelSize.normal
                                            color: Appearance.colors.colOnSurfaceVariant
                                        }

                                        ColumnLayout {
                                            Layout.fillWidth: true
                                            spacing: 0
                                            StyledText {
                                                Layout.fillWidth: true
                                                text: cItem.modelData.composeService || cItem.modelData.name
                                                font.pixelSize: Appearance.font.pixelSize.normal
                                                color: Appearance.colors.colOnLayer0
                                                elide: Text.ElideRight
                                            }
                                            StyledText {
                                                text: cItem.modelData.state
                                                font.pixelSize: Appearance.font.pixelSize.smaller
                                                color: cItem.modelData.state === "running"
                                                       ? Appearance.colors.colPrimary
                                                       : Appearance.colors.colOnSurfaceVariant
                                            }
                                        }

                                        DialogButton {
                                            visible: cItem.modelData.state !== "running"
                                            buttonText: "Start"
                                            onClicked: Docker.startContainer(cItem.modelData.name)
                                        }
                                        DialogButton {
                                            visible: cItem.modelData.state === "running"
                                            buttonText: "Stop"
                                            colEnabled: Appearance.m3colors.m3error
                                            onClicked: Docker.stopContainer(cItem.modelData.name)
                                        }
                                        DialogButton {
                                            buttonText: "Restart"
                                            onClicked: Docker.restartContainer(cItem.modelData.name)
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // Separator between stacks
                    Rectangle {
                        width: parent.width
                        height: 1
                        color: Appearance.colors.colOutlineVariant
                    }
                }
            }

            // ── Standalone containers ──────────────────────────────────────
            Repeater {
                model: Docker.standaloneContainers

                Item {
                    id: sItem
                    required property var modelData
                    width: listCol.width
                    implicitHeight: sRow.implicitHeight + 14

                    Rectangle {
                        anchors.fill: parent
                        color: Appearance.colors.colPrimary
                        opacity: sItem.modelData.state === "running" ? 0.06 : 0
                    }

                    RowLayout {
                        id: sRow
                        anchors {
                            left: parent.left; right: parent.right
                            verticalCenter: parent.verticalCenter
                            leftMargin: Appearance.rounding.large
                            rightMargin: Appearance.rounding.large
                        }
                        spacing: 10

                        Rectangle {
                            width: 8; height: 8; radius: 4
                            color: sItem.modelData.state === "running"  ? Appearance.colors.colPrimary
                                 : sItem.modelData.state === "paused"   ? Appearance.m3colors.m3secondary
                                 : sItem.modelData.state === "exited"   ? Appearance.colors.colOnSurfaceVariant
                                 :                                         Appearance.m3colors.m3error
                        }

                        MaterialSymbol {
                            text: "deployed_code"
                            iconSize: Appearance.font.pixelSize.larger
                            color: Appearance.colors.colOnLayer0
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 0
                            StyledText {
                                Layout.fillWidth: true
                                text: sItem.modelData.name
                                font.pixelSize: Appearance.font.pixelSize.normal
                                color: Appearance.colors.colOnLayer0
                                elide: Text.ElideRight
                            }
                            StyledText {
                                text: sItem.modelData.state
                                font.pixelSize: Appearance.font.pixelSize.smaller
                                color: sItem.modelData.state === "running"
                                       ? Appearance.colors.colPrimary
                                       : Appearance.colors.colOnSurfaceVariant
                            }
                        }

                        DialogButton {
                            visible: sItem.modelData.state !== "running"
                            buttonText: "Start"
                            onClicked: Docker.startContainer(sItem.modelData.name)
                        }
                        DialogButton {
                            visible: sItem.modelData.state === "running"
                            buttonText: "Stop"
                            colEnabled: Appearance.m3colors.m3error
                            onClicked: Docker.stopContainer(sItem.modelData.name)
                        }
                        DialogButton {
                            buttonText: "Restart"
                            onClicked: Docker.restartContainer(sItem.modelData.name)
                        }
                    }
                }
            }

            // Empty state
            Item {
                width: listCol.width
                height: 48
                visible: Docker.available && !Docker.loading && Docker.containers.length === 0

                StyledText {
                    anchors.centerIn: parent
                    text: "No containers"
                    color: Appearance.colors.colOnLayer1
                }
            }
        }
    }

    WindowDialogSeparator {}

    WindowDialogButtonRow {
        Layout.fillWidth: true

        DialogButton {
            buttonText: "Refresh"
            onClicked: Docker.refresh()
        }
        Item { Layout.fillWidth: true }
        DialogButton {
            buttonText: "Close"
            onClicked: root.dismiss()
        }
    }
}
