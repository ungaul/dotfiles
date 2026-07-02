import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Qt.labs.synchronizer

Item {
    id: root
    required property var scopeRoot
    property int sidebarPadding: 10
    anchors.fill: parent
    property bool claudeCodeEnabled: Config.options.sidebar.claudeCode.enable
    property bool notesEnabled: Config.options.sidebar.notes.enable
    property var tabButtonList: [
        ...(root.claudeCodeEnabled ? [{"icon": "terminal", "name": "Claude Code"}] : []),
        ...(root.notesEnabled ? [{"icon": "edit_note", "name": "Notes"}] : []),
    ]
    property int tabCount: swipeView.count

    function focusActiveItem() {
        swipeView.currentItem.forceActiveFocus()
    }

    // Nothing previously called focusActiveItem(), so tab content (e.g. the
    // embedded Claude Code terminal) never actually received keyboard focus
    // when the sidebar was opened after startup.
    Connections {
        target: GlobalStates
        function onSidebarLeftOpenChanged() {
            if (GlobalStates.sidebarLeftOpen)
                root.focusActiveItem();
        }
    }
    Connections {
        target: swipeView
        function onCurrentIndexChanged() {
            root.focusActiveItem();
        }
    }

    Keys.onPressed: (event) => {
        if (event.modifiers === Qt.ControlModifier) {
            if (event.key === Qt.Key_PageDown) {
                swipeView.incrementCurrentIndex()
                event.accepted = true;
            }
            else if (event.key === Qt.Key_PageUp) {
                swipeView.decrementCurrentIndex()
                event.accepted = true;
            }
        }
    }

    ColumnLayout {
        anchors {
            fill: parent
            margins: sidebarPadding
        }
        spacing: sidebarPadding

        Toolbar {
            visible: tabButtonList.length > 0
            Layout.alignment: Qt.AlignHCenter
            enableShadow: false
            ToolbarTabBar {
                id: tabBar
                Layout.alignment: Qt.AlignHCenter
                tabButtonList: root.tabButtonList
                currentIndex: swipeView.currentIndex
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            implicitWidth: swipeView.implicitWidth
            implicitHeight: swipeView.implicitHeight
            radius: Appearance.rounding.normal
            color: Appearance.colors.colLayer1

            SwipeView { // Content pages
                id: swipeView
                anchors.fill: parent
                spacing: 10
                currentIndex: tabBar.currentIndex

                clip: true
                // layer.enabled + OpacityMask (rounded-corner mask) interferes with
                // input delivery to embedded native-ish items like QMLTermWidget.
                // clip: true alone still rounds the visible edges well enough.
                layer.enabled: false

                contentChildren: [
                    ...(root.claudeCodeEnabled ? [claudeCode.createObject()] : []),
                    ...(root.notesEnabled ? [notes.createObject()] : []),
                    ...(root.tabButtonList.length === 0 ? [placeholder.createObject()] : []),
                ]
            }
        }

        Component {
            id: claudeCode
            ClaudeCode {}
        }
        Component {
            id: notes
            ScratchpadNotes {}
        }
        Component {
            id: placeholder
            Item {
                StyledText {
                    anchors.centerIn: parent
                    text: "Enjoy your empty sidebar..."
                    color: Appearance.colors.colSubtext
                }
            }
        }
    }
}