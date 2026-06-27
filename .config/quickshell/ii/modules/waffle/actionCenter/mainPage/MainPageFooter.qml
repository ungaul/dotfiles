import QtQuick
import QtQuick.Layouts
import Quickshell
import qs
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.waffle.looks
import qs.modules.waffle.actionCenter

FooterRectangle {

    // Battery button
    WBorderlessButton {
        visible: Battery.available
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        anchors.leftMargin: 12

        contentItem: Row {
            spacing: 4

            FluentIcon {
                anchors.verticalCenter: parent.verticalCenter
                icon: WIcons.batteryLevelIcon
                FluentIcon {
                    anchors.fill: parent
                    icon: WIcons.batteryIcon
                }
            }
            WText {
                anchors.verticalCenter: parent.verticalCenter
                text: `${Math.round(Battery.percentage * 100) || 0}%`
            }
        }
    }

    // Settings button
    WBorderlessButton {
        anchors.verticalCenter: parent.verticalCenter
        anchors.right: parent.right
        anchors.rightMargin: 12

        onClicked: {
            GlobalStates.sidebarLeftOpen = false;
            // Bare `qs -p settings.qml` can fail to render without XDG_CURRENT_DESKTOP
            // set (settings.qml relies on portals/native styling gated on it) — use the
            // same launcher + fallback as the SUPER+I keybind (hyprland/variables.lua).
            Quickshell.execDetached(["bash", "-c", `XDG_CURRENT_DESKTOP=gnome ~/.config/hypr/hyprland/scripts/launch_first_available.sh 'qs -p ${Quickshell.shellPath("settings.qml")}' 'systemsettings'`]);
        }

        contentItem: FluentIcon {
            icon: "settings"
        }
    }
}
