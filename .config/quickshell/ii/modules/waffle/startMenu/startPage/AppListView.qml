pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.waffle.looks

WListView {
    id: root

    clip: true
    spacing: 1

    model: Array.from(DesktopEntries.applications.values).sort((a, b) => a.name.localeCompare(b.name))

    section {
        property: "name"
        criteria: ViewSection.FirstCharacter
        labelPositioning: ViewSection.InlineLabels
        delegate: Item {
            id: sectionHeader
            required property string section
            implicitHeight: sectionText.implicitHeight + 22
            width: ListView.view?.width ?? 0
            WText {
                id: sectionText
                anchors {
                    left: parent.left
                    leftMargin: 10
                    bottom: parent.bottom
                    bottomMargin: 6
                }
                text: sectionHeader.section.toUpperCase()
                font.pixelSize: Looks.font.pixelSize.normal
                font.weight: Looks.font.weight.strong
                color: Looks.colors.accentUnfocused
            }
        }
    }

    delegate: WButton {
        id: appButton
        required property var modelData
        width: ListView.view?.width ?? 0
        implicitHeight: 46
        horizontalPadding: 10
        verticalPadding: 0

        property bool pinnedStart: LauncherApps.isPinned(appButton.modelData.id)
        property bool pinnedTaskbar: TaskbarApps.isPinned(appButton.modelData.id)

        contentItem: RowLayout {
            spacing: 10
            WAppIcon {
                iconName: appButton.modelData.icon
                implicitSize: 26
                tryCustomIcon: false
            }
            WText {
                Layout.fillWidth: true
                text: appButton.modelData.name
                elide: Text.ElideRight
                font.pixelSize: Looks.font.pixelSize.large
            }
        }

        onClicked: {
            GlobalStates.searchOpen = false;
            appButton.modelData.execute();
        }

        altAction: () => {
            appMenu.popup();
        }

        WMenu {
            id: appMenu
            downDirection: true

            WMenuItem {
                icon.name: appButton.pinnedStart ? "pin-off" : "pin"
                text: appButton.pinnedStart ? "Unpin from Start" : "Pin to Start"
                onTriggered: {
                    LauncherApps.togglePin(appButton.modelData.id);
                }
            }
            WMenuItem {
                icon.name: appButton.pinnedTaskbar ? "pin-off" : "pin"
                text: appButton.pinnedTaskbar ? "Unpin from taskbar" : "Pin to taskbar"
                onTriggered: {
                    TaskbarApps.togglePin(appButton.modelData.id);
                }
            }
        }
    }
}
