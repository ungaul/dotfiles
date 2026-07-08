pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.models.quickToggles
import qs.modules.common.functions
import qs.modules.waffle.looks
import qs.modules.waffle.actionCenter
import qs.modules.waffle.actionCenter.toggles

Item {
    id: root

    property int columns: 3
    property int rows: 2
    property list<string> toggles: Config.options.waffles.actionCenter.toggles
    readonly property bool editing: ActionCenterContext.editingToggles

    property real padding: 22
    property real reducedBottomPadding: 12
    // Fixed, mode-independent viewport height: the content (in either the normal
    // toggle grid or the edit-mode picker) scrolls inside this instead of resizing
    // it. The action center's PanelWindow size is tied to this container's
    // implicitHeight, and it turns out *any* change to that height — whether from
    // paging, scrolling, or switching to/from edit mode — gets treated by
    // Hyprland's focus grab as if focus left the window, instantly closing the
    // whole action center. Keeping this height constant regardless of content
    // or mode is what actually prevents that.
    readonly property real viewportHeight: (48 + 36) * root.rows + (root.rows - 1) * 12
    implicitHeight: root.viewportHeight + root.padding * 2 - root.reducedBottomPadding

    function isToggleEnabled(id) {
        return root.toggles.includes(id);
    }

    function setToggleEnabled(id, on) {
        const current = Config.options.waffles.actionCenter.toggles;
        if (on) {
            if (!current.includes(id))
                Config.options.waffles.actionCenter.toggles = current.concat([id]);
        } else {
            Config.options.waffles.actionCenter.toggles = current.filter(t => t !== id);
        }
    }

    clip: true

    Flickable {
        id: editFlick
        visible: root.editing
        anchors {
            fill: parent
            leftMargin: root.padding
            rightMargin: root.padding
            topMargin: root.padding
            bottomMargin: root.padding - root.reducedBottomPadding
        }
        clip: true
        contentWidth: width
        contentHeight: editGrid.implicitHeight
        boundsBehavior: Flickable.DragOverBounds
        ScrollBar.vertical: WScrollBar {}

        GridLayout {
            id: editGrid
            width: editFlick.width
            columns: root.columns
            rowSpacing: 12
            columnSpacing: 12

            Repeater {
                model: ToggleCatalog.all
                delegate: EditToggleChip {
                    required property var modelData
                    toggleName: modelData.name
                    toggleIcon: modelData.icon
                    toggleEnabled: root.isToggleEnabled(modelData.id)
                    onClicked: root.setToggleEnabled(modelData.id, !toggleEnabled)
                }
            }
        }
    }

    Flickable {
        id: normalFlick
        visible: !root.editing
        anchors {
            fill: parent
            leftMargin: root.padding
            rightMargin: root.padding
            topMargin: root.padding
            bottomMargin: root.padding - root.reducedBottomPadding
        }
        clip: true
        contentWidth: width
        contentHeight: normalGrid.implicitHeight
        boundsBehavior: Flickable.DragOverBounds
        ScrollBar.vertical: WScrollBar {}

        GridLayout {
            id: normalGrid
            width: normalFlick.width
            columns: root.columns
            rowSpacing: 12
            columnSpacing: 12

            Repeater {
                model: ScriptModel { values: root.toggles }
                delegate: ActionCenterTogglesDelegateChooser {}
            }
        }
    }

    component EditToggleChip: WButton {
        id: chip
        required property string toggleName
        required property string toggleIcon
        required property bool toggleEnabled

        Layout.fillWidth: true
        implicitWidth: 96
        implicitHeight: 64
        checked: chip.toggleEnabled

        contentItem: ColumnLayout {
            spacing: 4
            Item {
                Layout.alignment: Qt.AlignHCenter
                implicitWidth: 22
                implicitHeight: 22
                FluentIcon {
                    anchors.centerIn: parent
                    icon: chip.toggleIcon
                    implicitSize: 18
                    color: chip.toggleEnabled ? Looks.colors.accentFg : Looks.colors.fg1
                }
            }
            WText {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
                font.pixelSize: Looks.font.pixelSize.smaller
                text: chip.toggleName
                color: chip.toggleEnabled ? Looks.colors.accentFg : Looks.colors.fg1
            }
            FluentIcon {
                Layout.alignment: Qt.AlignHCenter
                visible: chip.toggleEnabled
                icon: "checkmark"
                implicitSize: 12
                color: Looks.colors.accentFg
            }
        }
    }
}
