import QtQuick
import QtQuick.Layouts
import Quickshell
import qs
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.waffle.looks
import qs.modules.waffle.actionCenter

BodyRectangle {
    id: root
    implicitHeight: contentLayout.implicitHeight

    ColumnLayout {
        id: contentLayout
        anchors.fill: parent
        spacing: 0

        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: 22
            Layout.rightMargin: 14
            Layout.topMargin: 10

            WText {
                Layout.fillWidth: true
                text: ActionCenterContext.editingToggles ? "Edit quick settings" : "Quick settings"
                font.weight: Looks.font.weight.strong
            }
            WPanelIconButton {
                iconName: ActionCenterContext.editingToggles ? "checkmark" : "image-edit"
                onClicked: ActionCenterContext.editingToggles = !ActionCenterContext.editingToggles
            }
        }

        MainPageBodyToggles {
            id: togglesContainer
            Layout.fillWidth: true
        }

        Rectangle {
            implicitHeight: 1
            Layout.fillWidth: true
            color: Looks.colors.bg1Border
        }

        MainPageBodySliders {
            Layout.margins: 12
            Layout.topMargin: 18
            Layout.bottomMargin: 14
        }
    }
}
