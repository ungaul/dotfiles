import QtQuick
import QtQuick.Layouts
import Quickshell
import qs
import qs.services
import qs.modules.common
import qs.modules.waffle.looks

WBarAttachedPanelContent {
    id: root

    property Timer timer: Timer {
        id: autoCloseTimer
        running: true
        interval: Config.options.osd.timeout
        repeat: false
        onTriggered: {
            root.close();
        }
    }

    Connections {
        target: Audio
        function onSinkChanged() {
            root.timer.restart();
        }
        function onProfileCycled() {
            root.timer.restart();
        }
    }

    contentItem: WPane {
        anchors.centerIn: parent
        borderColor: Looks.colors.ambientShadow

        contentItem: Item {
            implicitWidth: Math.max(170, contentRow.implicitWidth + 24)
            implicitHeight: 46

            RowLayout {
                id: contentRow
                anchors.fill: parent
                anchors.margins: 12

                spacing: 12

                FluentIcon {
                    Layout.alignment: Qt.AlignVCenter
                    icon: "speaker"
                    implicitSize: 18
                }

                Text {
                    Layout.alignment: Qt.AlignVCenter
                    Layout.fillWidth: true
                    color: Looks.colors.textMain
                    text: Audio.lastCycledProfileLabel || (Audio.sink ? Audio.friendlyDeviceName(Audio.sink) : "")
                    elide: Text.ElideRight
                }
            }
        }
    }
}
