import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

// Persistent quick notes/scratchpad. Shares the same backing file as the
// overlay notes widget (Directories.notesPath), so it stays in sync with it.
FocusScope {
    id: root

    property alias content: textInput.text

    function saveContent() {
        noteFile.setText(root.content);
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 4

        ScrollView {
            id: editorScrollView
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            ScrollBar.vertical.policy: ScrollBar.AsNeeded

            StyledTextArea { // Direct child of ScrollView for proper scrolling
                id: textInput
                focus: true
                width: editorScrollView.availableWidth
                wrapMode: TextEdit.Wrap
                placeholderText: "Write something here..."
                selectByMouse: true
                persistentSelection: true
                textFormat: TextEdit.PlainText
                background: null
                padding: 12

                onTextChanged: saveDebounce.restart()

                HoverHandler {
                    cursorShape: Qt.IBeamCursor
                }
            }
        }

        StyledText {
            Layout.fillWidth: true
            Layout.rightMargin: 8
            horizontalAlignment: Text.AlignRight
            text: saveDebounce.running ? "Saving..." : "Saved"
            color: Appearance.colors.colSubtext
            font.pixelSize: Appearance.font.pixelSize.smaller
        }
    }

    Timer {
        id: saveDebounce
        interval: 500
        onTriggered: root.saveContent()
    }

    FileView {
        id: noteFile
        path: Qt.resolvedUrl(Directories.notesPath)
        onLoaded: root.content = noteFile.text()
        onLoadFailed: error => {
            if (error === FileViewError.FileNotFound) {
                root.content = "";
                noteFile.setText(root.content);
            } else {
                console.log("[Sidebar Notes] Error loading file: " + error);
            }
        }
    }
}
