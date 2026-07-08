import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.services
import qs.modules.common
import qs.modules.waffle.looks

MouseArea {
    id: root

    Layout.fillHeight: true
    implicitHeight: appRow.implicitHeight
    implicitWidth: appRow.implicitWidth
    hoverEnabled: true

    function showPreviewPopup(appEntry, button) {
        previewPopup.show(appEntry, button);
    }

    Behavior on implicitWidth {
        animation: Looks.transition.move.createObject(this)
    }

    // Last pinned app the dragged button was hovering over when released; consumed on drop.
    property string pendingDropTargetAppId: ""

    WListView {
        id: appRow
        anchors {
            top: parent.top
            bottom: parent.bottom
        }
        orientation: Qt.Horizontal
        spacing: 0
        implicitWidth: contentWidth
        clip: true
        interactive: false
        // TODO: Include only apps (and windows) in current workspace only | wait, does that even make sense in a Hyprland workflow?
        model: ScriptModel {
            objectProp: "appId"
            values: TaskbarApps.apps.filter(app => app.appId !== "SEPARATOR")
        }
        delegate: Item {
            id: dragWrapper
            required property var modelData
            readonly property bool draggable: modelData.appId !== "SEPARATOR" && modelData.pinned

            width: button.implicitWidth
            height: button.implicitHeight
            z: dragHandler.active ? 1 : 0

            Drag.active: dragHandler.active
            Drag.source: dragWrapper
            Drag.hotSpot.x: width / 2
            Drag.hotSpot.y: height / 2

            TaskAppButton {
                id: button
                anchors.fill: parent
                appEntry: dragWrapper.modelData
                opacity: dragHandler.active ? 0.4 : 1

                onHoverPreviewRequested: {
                    root.showPreviewPopup(appEntry, this);
                }
                onHoverPreviewDismissed: {
                    previewPopup.close();
                }
            }

            // Drag-to-reorder. A DragHandler only grabs once the gesture clearly
            // moves past the press point, so plain clicks on the button underneath
            // (handled by its own internal MouseArea) still work normally.
            // The model is only reordered on drop, not live during the drag, so it
            // never fights the ListView's own positioning of delegates mid-gesture.
            DragHandler {
                id: dragHandler
                target: dragWrapper.draggable ? dragWrapper : null
                enabled: dragWrapper.draggable
                yAxis.enabled: false
                onActiveChanged: {
                    if (active) return;
                    dragWrapper.Drag.drop();
                    // Defer to the next event loop tick: reordering the model (and thus
                    // potentially destroying/recreating this very delegate) synchronously
                    // here, while Qt is still delivering the pointer-release event to this
                    // DragHandler, segfaults (use-after-free on the delegate mid-delivery).
                    const draggedAppId = dragWrapper.modelData.appId;
                    const targetAppId = root.pendingDropTargetAppId;
                    root.pendingDropTargetAppId = "";
                    Qt.callLater(() => {
                        if (targetAppId !== "") {
                            TaskbarApps.movePinnedBefore(draggedAppId, targetAppId);
                        }
                        appRow.forceLayout();
                    });
                }
            }

            DropArea {
                anchors.fill: parent
                enabled: dragWrapper.modelData.appId !== "SEPARATOR"
                onEntered: drag => {
                    if (drag.source === dragWrapper) return;
                    root.pendingDropTargetAppId = dragWrapper.modelData.appId;
                }
                onExited: {
                    if (root.pendingDropTargetAppId === dragWrapper.modelData.appId) {
                        root.pendingDropTargetAppId = "";
                    }
                }
            }
        }
    }

    // Previews popup
    TaskPreview {
        id: previewPopup
        tasksHovered: root.containsMouse
        anchor.window: root.QsWindow.window
    }
}
