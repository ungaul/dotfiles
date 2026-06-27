pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.waffle.looks

WBarAttachedPanelContent {
    id: root

    contentItem: WPane {
        contentItem: ColumnLayout {
            id: columnLayout
            implicitWidth: 340
            spacing: 8

            RowLayout {
                Layout.fillWidth: true
                Layout.leftMargin: 14
                Layout.rightMargin: 14
                Layout.topMargin: 10

                WText {
                    Layout.fillWidth: true
                    text: "Clipboard history"
                    font {
                        weight: Looks.font.weight.stronger
                        pixelSize: Looks.font.pixelSize.large
                    }
                }

                WBorderlessButton {
                    visible: Cliphist.entries.length > 0
                    implicitHeight: 26
                    text: "Clear all"
                    onClicked: Cliphist.wipe()
                }
            }

            WListView {
                id: listView
                Layout.fillWidth: true
                Layout.preferredHeight: Math.min(contentHeight, 420)
                Layout.bottomMargin: 10
                clip: true
                spacing: 6

                model: ScriptModel {
                    values: Cliphist.entries
                }

                delegate: ClipboardEntryCard {
                    required property string modelData
                    entry: modelData
                }
            }

            WText {
                visible: Cliphist.entries.length === 0
                Layout.fillWidth: true
                Layout.bottomMargin: 16
                horizontalAlignment: Text.AlignHCenter
                color: Looks.colors.subfg
                text: "Nothing copied yet"
            }
        }
    }

    component ClipboardEntryCard: Rectangle {
        id: card
        required property string entry

        readonly property bool isImage: Cliphist.entryIsImage(entry)
        readonly property string previewText: entry.replace(/^\s*\S+\s+/, "")

        anchors.left: parent?.left
        anchors.right: parent?.right
        anchors.leftMargin: 14
        anchors.rightMargin: 14
        implicitHeight: rowLayout.implicitHeight + 16
        height: implicitHeight
        radius: Looks.radius.medium
        color: cardMouseArea.containsMouse ? Looks.colors.bg2Hover : Looks.colors.bg2

        MouseArea {
            id: cardMouseArea
            anchors.fill: parent
            hoverEnabled: true
            onClicked: {
                Cliphist.paste(card.entry);
                root.close();
            }
        }

        RowLayout {
            id: rowLayout
            anchors {
                left: parent.left
                right: parent.right
                verticalCenter: parent.verticalCenter
                leftMargin: 10
                rightMargin: 10
                topMargin: 8
                bottomMargin: 8
            }
            spacing: 8

            Loader {
                active: card.isImage
                sourceComponent: CliphistImage {
                    entry: card.entry
                    maxWidth: 280
                    maxHeight: 120
                }
            }

            WText {
                visible: !card.isImage
                Layout.fillWidth: true
                text: card.previewText
                wrapMode: Text.Wrap
                maximumLineCount: 4
                elide: Text.ElideRight
            }

            WBorderlessButton {
                implicitWidth: 26
                implicitHeight: 26
                opacity: cardMouseArea.containsMouse ? 1 : 0
                text: "×"
                onClicked: Cliphist.deleteEntry(card.entry)
            }
        }
    }
}
