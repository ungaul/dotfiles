pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell
import qs
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.modules.waffle.looks

Item {
    id: root
    Layout.alignment: Qt.AlignTop
    property alias sourceSize: avatar.sourceSize
    implicitWidth: avatar.sourceSize.width
    implicitHeight: avatar.sourceSize.height

    Rectangle {
        id: placeholder
        anchors.fill: parent
        radius: width / 2
        visible: avatar.opacity < 1
        color: Looks.colors.bg2

        FluentIcon {
            anchors.centerIn: parent
            icon: "person"
            implicitSize: parent.width * 0.6
        }
    }

    StyledImage {
        id: avatar
        anchors.fill: parent
        sourceSize: Qt.size(32, 32)
        source: Directories.userAvatarPathAccountsService
        fallbacks: [Directories.userAvatarPathRicersAndWeirdSystems, Directories.userAvatarPathRicersAndWeirdSystems2]

        layer.enabled: true
        layer.effect: OpacityMask {
            maskSource: Circle {
                diameter: avatar.height
            }
        }
    }
}
