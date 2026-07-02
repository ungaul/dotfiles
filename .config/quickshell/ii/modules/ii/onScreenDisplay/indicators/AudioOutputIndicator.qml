import qs.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Layouts

Item {
    id: root

    implicitWidth: Appearance.sizes.osdWidth + 2 * Appearance.sizes.elevationMargin
    implicitHeight: indicator.implicitHeight + 2 * Appearance.sizes.elevationMargin

    StyledRectangularShadow {
        target: indicator
    }
    Rectangle {
        id: indicator
        anchors {
            fill: parent
            margins: Appearance.sizes.elevationMargin
        }
        radius: Appearance.rounding.full
        color: Appearance.colors.colLayer0

        implicitWidth: row.implicitWidth
        implicitHeight: row.implicitHeight

        RowLayout {
            id: row
            Layout.margins: 10
            anchors.fill: parent
            spacing: 10

            Item {
                implicitWidth: 30
                implicitHeight: 30
                Layout.alignment: Qt.AlignVCenter
                Layout.leftMargin: 10
                Layout.topMargin: 9
                Layout.bottomMargin: 9

                MaterialSymbol {
                    anchors.centerIn: parent
                    color: Appearance.colors.colOnLayer0
                    renderType: Text.QtRendering
                    text: "speaker"
                    iconSize: 20
                }
            }

            StyledText {
                color: Appearance.colors.colOnLayer0
                font.pixelSize: Appearance.font.pixelSize.small
                Layout.fillWidth: true
                Layout.rightMargin: 20
                text: Audio.lastCycledProfileLabel || (Audio.sink ? Audio.friendlyDeviceName(Audio.sink) : "")
            }
        }
    }
}
