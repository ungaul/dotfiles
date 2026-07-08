pragma ComponentBehavior: Bound
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland

PopupWindow {
    id: root

    property Item anchorItem: null
    // List of { label, icon, action } or null for a separator
    property var entries: []

    property real horizontalPadding: 4
    property real verticalPadding: 4

    function openAt(item) {
        root.anchorItem = item;
        root.visible = true;
        focusGrab.active = true;
    }

    function close() {
        focusGrab.active = false;
        root.visible = false;
    }

    visible: false
    color: "transparent"

    anchor {
        window: anchorItem?.QsWindow.window ?? null
        item: anchorItem
        edges: Edges.Bottom | Edges.Left
        gravity: Edges.Bottom | Edges.Right
    }

    implicitWidth: menuColumn.implicitWidth + horizontalPadding * 2 + background.padding * 2
    implicitHeight: menuColumn.implicitHeight + verticalPadding * 2 + background.padding * 2

    HyprlandFocusGrab {
        id: focusGrab
        active: false
        windows: [root]
        onCleared: root.close()
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: root.close()

        StyledRectangularShadow {
            target: background
        }

        Rectangle {
            id: background
            readonly property real padding: 4
            anchors.fill: parent
            anchors.margins: root.horizontalPadding
            color: Appearance.colors.colLayer0
            radius: Appearance.rounding.normal
            border.width: 1
            border.color: Appearance.colors.colLayer0Border
            clip: true

            ColumnLayout {
                id: menuColumn
                anchors {
                    fill: parent
                    margins: background.padding
                }
                spacing: 0

                Repeater {
                    model: root.entries
                    delegate: Loader {
                        id: entryLoader
                        required property var modelData
                        Layout.fillWidth: true
                        active: true
                        sourceComponent: modelData === null ? separatorComponent : buttonComponent

                        Component {
                            id: separatorComponent
                            Rectangle {
                                Layout.fillWidth: true
                                implicitHeight: 1
                                color: Appearance.colors.colSubtext
                                Layout.topMargin: 4
                                Layout.bottomMargin: 4
                            }
                        }

                        Component {
                            id: buttonComponent
                            RippleButton {
                                buttonRadius: Appearance.rounding.small
                                horizontalPadding: 12
                                implicitWidth: Math.max(160, contentItem.implicitWidth + horizontalPadding * 2)
                                implicitHeight: 36
                                Layout.fillWidth: true

                                releaseAction: () => {
                                    root.close();
                                    entryLoader.modelData.action();
                                }

                                contentItem: RowLayout {
                                    anchors {
                                        verticalCenter: parent.verticalCenter
                                        left: parent.left
                                        right: parent.right
                                        leftMargin: 12
                                        rightMargin: 12
                                    }
                                    spacing: 8
                                    MaterialSymbol {
                                        iconSize: 18
                                        text: entryLoader.modelData.icon ?? ""
                                        visible: text.length > 0
                                    }
                                    StyledText {
                                        Layout.fillWidth: true
                                        text: entryLoader.modelData.label
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
