pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Qt.labs.folderlistmodel
import Quickshell
import Quickshell.Io
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions

Item {
    id: root

    function openPath(path, isDir) {
        if (isDir) {
            Quickshell.execDetached(["nautilus", path]);
        } else {
            Quickshell.execDetached(["xdg-open", path]);
        }
    }

    function renamePath(path) {
        const script = `old="$1"; dir=$(dirname -- "$old"); base=$(basename -- "$old"); new_name=$(zenity --entry --title="Rename" --text="New name:" --entry-text="$base" 2>/dev/null); if [ -n "$new_name" ]; then mv -n -- "$old" "$dir/$new_name"; fi`;
        Quickshell.execDetached(["bash", "-c", script, "bash", path]);
    }

    function trashPath(path) {
        // Falls back to a manual move into ~/.local/share/Trash if gio's trash
        // backend (gvfs) isn't available, so delete always does something.
        const script = `p="$1"; gio trash -- "$p" 2>/dev/null && exit 0; mkdir -p "$HOME/.local/share/Trash/files"; mv -n -- "$p" "$HOME/.local/share/Trash/files/$(basename -- "$p")"`;
        Quickshell.execDetached(["bash", "-c", script, "bash", path]);
    }

    function copyPath(path) {
        Quickshell.execDetached(["bash", "-c", `printf '%s' "$1" | wl-copy`, "bash", path]);
    }

    function openTerminalHere() {
        Quickshell.execDetached(["kitty", "-1", "--working-directory", root.desktopPath]);
    }

    function createNewFolder() {
        const script = `dir="$1"; name=$(zenity --entry --title="New Folder" --text="Folder name:" --entry-text="New Folder" 2>/dev/null); [ -z "$name" ] && exit 0; mkdir -p -- "$dir/$name"`;
        Quickshell.execDetached(["bash", "-c", script, "bash", root.desktopPath]);
    }

    function createNewFile() {
        const script = `dir="$1"; name=$(zenity --entry --title="New File" --text="File name:" --entry-text="New File.txt" 2>/dev/null); [ -z "$name" ] && exit 0; touch -- "$dir/$name"`;
        Quickshell.execDetached(["bash", "-c", script, "bash", root.desktopPath]);
    }

    function refresh() {
        const current = folderModel.folder;
        folderModel.folder = "";
        folderModel.folder = current;
    }

    function launchWith(desktopId, path) {
        Quickshell.execDetached(["gio", "launch", desktopId, path]);
    }

    // Re-opens the shared context menu at the last click position with new entries
    function reopenMenu(entries) {
        contextMenu.entries = entries;
        contextMenu.openAt(contextMenuAnchor);
    }

    function openIconMenu(path, isDir) {
        root.reopenMenu([
            {
                label: "Open",
                icon: "open_in_new",
                action: () => root.openPath(path, isDir)
            },
            {
                label: "Open With…",
                icon: "apps",
                action: () => root.requestOpenWith(path)
            },
            null,
            {
                label: "Rename",
                icon: "edit",
                action: () => root.renamePath(path)
            },
            {
                label: "Copy Path",
                icon: "content_copy",
                action: () => root.copyPath(path)
            },
            null,
            {
                label: "Move to Trash",
                icon: "delete",
                action: () => root.trashPath(path)
            },
        ]);
    }

    function openBackgroundMenu() {
        root.reopenMenu([
            {
                label: "Open Terminal Here",
                icon: "terminal",
                action: () => root.openTerminalHere()
            },
            {
                label: "New Folder",
                icon: "create_new_folder",
                action: () => root.createNewFolder()
            },
            {
                label: "New File",
                icon: "note_add",
                action: () => root.createNewFile()
            },
            null,
            {
                label: "Refresh",
                icon: "refresh",
                action: () => root.refresh()
            },
        ]);
    }

    function requestOpenWith(path) {
        openWithProc.targetPath = path;
        openWithProc.running = false;
        openWithProc.running = true;
    }

    property string selectedFileName: ""

    required property int screenWidth
    required property int screenHeight

    readonly property var configEntry: Config.options.background.widgets.desktopIcons
    readonly property string desktopPath: (configEntry.path && configEntry.path.length > 0) ? configEntry.path : `${Directories.home}/Desktop`

    readonly property real cellWidth: configEntry.gridCellWidth
    readonly property real cellHeight: configEntry.gridCellHeight
    // Pitch = icon box size + gap between cells; used for grid placement/spacing
    readonly property real pitchWidth: cellWidth + configEntry.gridSpacingX
    readonly property real pitchHeight: cellHeight + configEntry.gridSpacingY

    // Reserve space so icons never sit behind the bar or the dock
    readonly property real dockReservedHeight: (Config.options.dock?.height ?? 70) + Appearance.sizes.elevationMargin + Appearance.sizes.hyprlandGapsOut
    readonly property real topMargin: 20 + (Config.options.bar.bottom ? 0 : Appearance.sizes.barHeight)
    readonly property real bottomMargin: 20 + (Config.options.bar.bottom ? Appearance.sizes.barHeight : 0) + dockReservedHeight
    readonly property real leftMargin: 20
    readonly property real rightMargin: 20

    readonly property int columns: Math.max(1, Math.floor((root.screenWidth - leftMargin - rightMargin) / pitchWidth))
    readonly property int rows: Math.max(1, Math.floor((root.screenHeight - topMargin - bottomMargin) / pitchHeight))

    anchors.fill: parent
    visible: !GlobalStates.screenLocked

    FolderListModel {
        id: folderModel
        folder: `file://${root.desktopPath}`
        showDirs: true
        showDotAndDotDot: false
        showHidden: false
        sortField: FolderListModel.Name
    }

    // Finds apps registered for a file's mimetype; emits "desktopId\tName" lines
    Process {
        id: openWithProc
        property string targetPath: ""
        running: false
        command: ["bash", "-c", `
file="$1"
mime=$(file --mime-type -b -- "$file" 2>/dev/null)
[ -z "$mime" ] && exit 0
gio mime "$mime" 2>/dev/null | awk '
  /Registered applications:/ { flag=1; next }
  /^[A-Za-z].*:$/ { flag=0 }
  flag && NF { print $1 }
' | while read -r id; do
  for d in "$HOME/.local/share/applications" /usr/local/share/applications /usr/share/applications; do
    f="$d/$id"
    if [ -f "$f" ]; then
      name=$(grep -m1 '^Name=' "$f" | cut -d= -f2-)
      printf '%s\\t%s\\n' "$id" "\${name:-$id}"
      break
    fi
  done
done
`, "bash", openWithProc.targetPath]
        stdout: StdioCollector {
            id: openWithCollector
            onStreamFinished: {
                const lines = text.trim().length > 0 ? text.trim().split("\n") : [];
                const path = openWithProc.targetPath;
                const appEntries = lines.map(line => {
                    const [id, name] = line.split("\t");
                    return {
                        label: name || id,
                        icon: "apps",
                        action: () => root.launchWith(id, path)
                    };
                });
                root.reopenMenu(appEntries.length > 0 ? appEntries : [
                    {
                        label: "No applications found",
                        icon: "block",
                        action: () => {}
                    }
                ]);
            }
        }
    }

    DesktopIconContextMenu {
        id: contextMenu
    }

    // 1x1 tracker positioned at the cursor so the menu opens exactly where clicked
    Item {
        id: contextMenuAnchor
        width: 1
        height: 1
    }

    MouseArea {
        id: backgroundArea
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: mouse => {
            if (mouse.button === Qt.LeftButton) {
                root.selectedFileName = "";
                return;
            }
            contextMenuAnchor.x = mouse.x;
            contextMenuAnchor.y = mouse.y;
            root.openBackgroundMenu();
        }
    }

    // Tracks which (col, row) cells are currently taken, to auto-place icons that
    // don't have a saved position without overlapping ones that do.
    QtObject {
        id: placement
        property var occupied: ({})
        property int nextIndex: 0

        function key(col, row) {
            return `${col},${row}`;
        }

        function reserve(col, row) {
            occupied[key(col, row)] = true;
        }

        function nextFree() {
            while (nextIndex < root.columns * root.rows) {
                const col = Math.floor(nextIndex / root.rows);
                const row = nextIndex % root.rows;
                nextIndex++;
                if (!occupied[key(col, row)]) {
                    occupied[key(col, row)] = true;
                    return { col, row };
                }
            }
            // Grid is full; stack past the last row of the last column as a fallback
            const overflowCol = Math.floor(nextIndex / root.rows);
            const overflowRow = nextIndex % root.rows;
            nextIndex++;
            return { col: overflowCol, row: overflowRow };
        }
    }

    Repeater {
        id: repeater
        model: folderModel

        delegate: Item {
            id: delegateRoot
            required property string fileName
            required property string filePath
            required property bool fileIsDir
            required property url fileUrl
            required property int index

            property int col: 0
            property int row: 0

            width: root.cellWidth
            height: root.cellHeight
            x: root.leftMargin + col * root.pitchWidth
            y: root.topMargin + row * root.pitchHeight

            Drag.active: dragArea.drag.active

            Component.onCompleted: {
                const saved = Persistent.states.desktopIconPositions[delegateRoot.fileName];
                if (saved) {
                    placement.reserve(saved.col, saved.row);
                    delegateRoot.col = saved.col;
                    delegateRoot.row = saved.row;
                } else {
                    const pos = placement.nextFree();
                    delegateRoot.col = pos.col;
                    delegateRoot.row = pos.row;
                }
            }

            MouseArea {
                id: dragArea
                anchors.fill: parent
                hoverEnabled: true
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                drag.target: dragArea.pressedButtons === Qt.LeftButton ? delegateRoot : null
                drag.axis: Drag.XAndYAxis

                onDoubleClicked: {
                    root.openPath(delegateRoot.filePath, delegateRoot.fileIsDir);
                }

                onClicked: mouse => {
                    if (mouse.button === Qt.LeftButton) {
                        root.selectedFileName = delegateRoot.fileName;
                        return;
                    }
                    root.selectedFileName = delegateRoot.fileName;
                    const posInRoot = dragArea.mapToItem(root, mouse.x, mouse.y);
                    contextMenuAnchor.x = posInRoot.x;
                    contextMenuAnchor.y = posInRoot.y;
                    root.openIconMenu(delegateRoot.filePath, delegateRoot.fileIsDir);
                }

                onPressed: mouse => {
                    if (mouse.button === Qt.LeftButton)
                        root.selectedFileName = delegateRoot.fileName;
                }

                onReleased: {
                    if (!drag.active) return;

                    let newCol = Math.round((delegateRoot.x - root.leftMargin) / root.pitchWidth);
                    let newRow = Math.round((delegateRoot.y - root.topMargin) / root.pitchHeight);
                    newCol = Math.max(0, Math.min(root.columns - 1, newCol));
                    newRow = Math.max(0, Math.min(root.rows - 1, newRow));

                    const positions = Persistent.states.desktopIconPositions;
                    const updated = Object.assign({}, positions);
                    updated[delegateRoot.fileName] = { col: newCol, row: newRow };
                    Persistent.states.desktopIconPositions = updated;

                    delegateRoot.col = newCol;
                    delegateRoot.row = newRow;
                    delegateRoot.x = root.leftMargin + newCol * root.pitchWidth;
                    delegateRoot.y = root.topMargin + newRow * root.pitchHeight;
                }

                Rectangle {
                    readonly property bool selected: root.selectedFileName === delegateRoot.fileName
                    anchors.fill: parent
                    radius: Appearance.rounding.small
                    color: selected ? Appearance.colors.colPrimary : Appearance.colors.colLayer0
                    opacity: dragArea.drag.active ? 0.35 : selected ? 0.3 : (dragArea.containsMouse ? 0.18 : 0)
                    Behavior on opacity {
                        animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                    }
                }

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 8
                    spacing: 2

                    Loader {
                        id: iconLoader
                        Layout.alignment: Qt.AlignHCenter
                        Layout.preferredWidth: root.configEntry.iconSize
                        Layout.preferredHeight: root.configEntry.iconSize
                        active: true
                        sourceComponent: (!delegateRoot.fileIsDir && Images.isValidImageByName(delegateRoot.fileName)) ? thumbnailComponent : adwaitaIconComponent

                        Component {
                            id: thumbnailComponent
                            Image {
                                asynchronous: true
                                cache: false
                                fillMode: Image.PreserveAspectCrop
                                source: delegateRoot.fileUrl
                                sourceSize.width: root.configEntry.iconSize
                                sourceSize.height: root.configEntry.iconSize
                            }
                        }

                        Component {
                            id: adwaitaIconComponent
                            AdwaitaIcon {
                                fileModelData: delegateRoot
                                sourceSize.width: root.configEntry.iconSize
                                sourceSize.height: root.configEntry.iconSize
                            }
                        }
                    }

                    StyledText {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignHCenter
                        horizontalAlignment: Text.AlignHCenter
                        elide: Text.ElideRight
                        maximumLineCount: 2
                        wrapMode: Text.Wrap
                        font.pixelSize: Appearance.font.pixelSize.small
                        color: Appearance.colors.colOnLayer0
                        text: delegateRoot.fileName
                    }
                }
            }
        }
    }
}
