import QtQuick
import Quickshell
import qs
import qs.services
import qs.modules.common
import qs.modules.waffle.looks

// Windows-style language indicator: shows the active layout code (e.g. "ENG"),
// click cycles to the next configured keyboard layout. Only shown when more
// than one layout is configured, same gating as the ii panel's xkb indicator.
BarButton {
    id: root

    visible: HyprlandXkb.layoutCodes.length > 1
    implicitWidth: 40

    property bool clickLocked: false
    onClicked: {
        if (clickLocked) return;
        clickLocked = true;
        clickDebounce.restart();
        const configPath = Directories.config.toString().replace(/^file:\/\//, "");
        Quickshell.execDetached(["bash", configPath + "/hypr/hyprland/scripts/switch-keyboard-layout.sh"]);
    }

    Timer {
        id: clickDebounce
        interval: 400
        onTriggered: root.clickLocked = false
    }

    contentItem: Item {
        anchors.centerIn: parent
        implicitWidth: label.implicitWidth
        implicitHeight: label.implicitHeight

        WText {
            id: label
            anchors.centerIn: parent
            font.bold: true
            text: HyprlandXkb.currentLayoutCode.substring(0, 3).toUpperCase()
        }
    }

    BarToolTip {
        extraVisibleCondition: root.shouldShowTooltip
        text: qsTr("Switch keyboard layout")
    }
}
