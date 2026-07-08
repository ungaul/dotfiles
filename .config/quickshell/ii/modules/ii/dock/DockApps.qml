pragma ComponentBehavior: Bound
import Qt5Compat.GraphicalEffects
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Wayland
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions

Item {
    id: root
    property real maxWindowPreviewHeight: 200
    property real maxWindowPreviewWidth: 300
    property real windowControlsHeight: 30
    property real buttonPadding: 5

    property Item lastHoveredButton: null
    property bool buttonHovered: false
    property bool requestDockShow: previewPopup.show || contextMenuPopup.show

    // Passed from Dock.qml — closes context menu when dock slides away
    property bool dockRevealed: true
    onDockRevealedChanged: if (!dockRevealed) contextMenuPopup.show = false

    // Passed from Dock.qml — for auto-close when mouse leaves dock+menu area
    property bool dockContainsMouse: true

    // Context menu state
    property var contextMenuApp: null
    property real contextMenuCenterX: 0

    Layout.fillHeight: true
    Layout.topMargin: Appearance.sizes.hyprlandGapsOut
    implicitWidth: listView.implicitWidth

    function popupCenterXForButton(button) {
        if (!button || !root.QsWindow) return 0
        return root.QsWindow.mapFromItem(button, button.width / 2, 0).x
    }

    // Auto-close context menu when mouse leaves both dock and popup windows.
    // Timer gives a 150ms grace period while the pointer moves between them.
    function checkMenuAutoClose() {
        if (!root.dockContainsMouse && !contextMenuPopup.menuHovered)
            menuAutoCloseTimer.restart()
        else
            menuAutoCloseTimer.stop()
    }
    Timer {
        id: menuAutoCloseTimer
        interval: 150
        onTriggered: {
            if (!root.dockContainsMouse && !contextMenuPopup.menuHovered)
                contextMenuPopup.show = false
        }
    }
    onDockContainsMouseChanged: checkMenuAutoClose()
    Connections {
        target: contextMenuPopup
        function onMenuHoveredChanged() { root.checkMenuAutoClose() }
    }

    StyledListView {
        id: listView
        spacing: 2
        orientation: ListView.Horizontal
        interactive: false  // prevents the whole list from flicking during icon drag
        animateAppearance: false  // suppress add/remove fly-off animations during reorder
        anchors { top: parent.top; bottom: parent.bottom }
        implicitWidth: contentWidth

        Behavior on implicitWidth {
            animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
        }

        model: ScriptModel {
            objectProp: "appId"
            values: TaskbarApps.apps
        }

        delegate: DockAppButton {
            id: appButton
            required property var modelData
            required property int index

            readonly property bool isPinned: modelData.pinned === true && modelData.appId !== "SEPARATOR"
            property bool skipTranslateAnim: false

            appToplevel: modelData
            appListRoot: root
            topInset: Appearance.sizes.hyprlandGapsOut + root.buttonPadding
            bottomInset: Appearance.sizes.hyprlandGapsOut + root.buttonPadding

            z: dragHandler.active ? 10 : 0

            transform: Translate {
                x: (dragHandler.active && appButton.isPinned) ? dragHandler.activeTranslation.x : 0
                Behavior on x {
                    enabled: !dragHandler.active && !appButton.skipTranslateAnim
                    NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
                }
            }

            scale: (dragHandler.active && appButton.isPinned) ? 1.08 : 1
            Behavior on scale { NumberAnimation { duration: 150 } }

            onContextMenuRequested: {
                previewPopup.show = false
                root.contextMenuApp = appButton.modelData
                root.contextMenuCenterX = root.popupCenterXForButton(appButton)
                contextMenuPopup.show = true
            }

            DragHandler {
                id: dragHandler
                enabled: appButton.isPinned
                xAxis.enabled: true
                yAxis.enabled: false
                target: null
                grabPermissions: PointerHandler.CanTakeOverFromAnything

                property point lastScenePos: Qt.point(0, 0)

                onCentroidChanged: {
                    if (active) lastScenePos = centroid.scenePosition
                }

                onActiveChanged: {
                    if (active) {
                        appButton.skipTranslateAnim = false
                        lastScenePos = centroid.scenePosition
                        return
                    }

                    // mapFromItem(null, x, y) maps scene coords → listView local coords
                    const local = listView.mapFromItem(null, lastScenePos.x, lastScenePos.y)
                    const targetIdx = listView.indexAt(local.x + listView.contentX,
                                                       local.y + listView.contentY)
                    if (targetIdx < 0 || targetIdx === appButton.index) return

                    const targetApp = TaskbarApps.apps[targetIdx]
                    if (!targetApp || !targetApp.pinned || targetApp.appId === "SEPARATOR") return

                    const fromId = appButton.modelData.appId
                    const toId   = targetApp.appId
                    const pinnedApps = Config.options.dock.pinnedApps.slice()
                    const fromI = pinnedApps.findIndex(function(id) { return id.toLowerCase() === fromId })
                    const toI   = pinnedApps.findIndex(function(id) { return id.toLowerCase() === toId })

                    if (fromI >= 0 && toI >= 0 && fromI !== toI) {
                        // Snap translate to 0 instantly — don't animate while model is reordering
                        appButton.skipTranslateAnim = true
                        const moved = pinnedApps.splice(fromI, 1)[0]
                        pinnedApps.splice(toI, 0, moved)
                        Config.options.dock.pinnedApps = pinnedApps
                        Qt.callLater(function() { appButton.skipTranslateAnim = false })
                    }
                }
            }
        }
    }

    // ── Window preview popup ─────────────────────────────────────────────────

    PopupWindow {
        id: previewPopup
        property var appTopLevel: root.lastHoveredButton?.appToplevel
        property bool shouldShow: (popupMouseArea.containsMouse || root.buttonHovered) && appTopLevel && appTopLevel.toplevels && appTopLevel.toplevels.length > 0 && !contextMenuPopup.show
        property bool show: false
        property real cachedCenterX: 0

        Connections {
            target: root
            function onLastHoveredButtonChanged() {
                if (root.lastHoveredButton && root.QsWindow)
                    previewPopup.cachedCenterX = root.popupCenterXForButton(root.lastHoveredButton)
            }
            function onButtonHoveredChanged() {
                if (root.buttonHovered && root.lastHoveredButton && root.QsWindow)
                    previewPopup.cachedCenterX = root.popupCenterXForButton(root.lastHoveredButton)
                updateTimer.restart()
            }
        }

        onShouldShowChanged: updateTimer.restart()
        Timer { id: updateTimer; interval: 100; onTriggered: previewPopup.show = previewPopup.shouldShow }

        anchor {
            window: root.QsWindow.window
            adjustment: PopupAdjustment.None
            gravity: Edges.Top | Edges.Right
            edges: Edges.Top | Edges.Left
        }

        visible: popupBackground.opacity > 0
        color: "transparent"
        implicitWidth: root.QsWindow.window?.width ?? 1
        implicitHeight: popupMouseArea.implicitHeight + root.windowControlsHeight + Appearance.sizes.elevationMargin * 2

        MouseArea {
            id: popupMouseArea
            anchors.bottom: parent.bottom
            implicitWidth: popupBackground.implicitWidth + Appearance.sizes.elevationMargin * 2
            implicitHeight: root.maxWindowPreviewHeight + root.windowControlsHeight + Appearance.sizes.elevationMargin * 2
            hoverEnabled: true
            x: previewPopup.cachedCenterX - width / 2

            StyledRectangularShadow {
                target: popupBackground
                opacity: previewPopup.show ? 1 : 0
                visible: opacity > 0
                Behavior on opacity { animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this) }
            }

            Rectangle {
                id: popupBackground
                property real padding: 5
                opacity: previewPopup.show ? 1 : 0
                visible: opacity > 0
                Behavior on opacity { animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this) }
                clip: true
                color: Appearance.m3colors.m3surfaceContainer
                radius: Appearance.rounding.normal
                anchors.bottom: parent.bottom
                anchors.bottomMargin: Appearance.sizes.elevationMargin
                anchors.horizontalCenter: parent.horizontalCenter
                implicitHeight: previewRowLayout.implicitHeight + padding * 2
                implicitWidth: previewRowLayout.implicitWidth + padding * 2
                Behavior on implicitWidth { animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this) }
                Behavior on implicitHeight { animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this) }

                RowLayout {
                    id: previewRowLayout
                    anchors.centerIn: parent
                    Repeater {
                        model: ScriptModel { values: previewPopup.appTopLevel?.toplevels ?? [] }
                        RippleButton {
                            id: windowButton
                            Layout.fillHeight: true
                            required property var modelData
                            padding: 0
                            middleClickAction: () => { windowButton.modelData?.close() }
                            onClicked: { windowButton.modelData?.activate() }
                            contentItem: ColumnLayout {
                                implicitWidth: screencopyView.implicitWidth
                                implicitHeight: screencopyView.implicitHeight
                                ButtonGroup {
                                    contentWidth: parent.width - anchors.margins * 2
                                    StyledText {
                                        Layout.margins: 5
                                        Layout.fillWidth: true
                                        font.pixelSize: Appearance.font.pixelSize.small
                                        text: windowButton.modelData?.title
                                        elide: Text.ElideRight
                                        color: Appearance.m3colors.m3onSurface
                                    }
                                    GroupButton {
                                        colBackground: ColorUtils.transparentize(Appearance.colors.colSurfaceContainer)
                                        baseWidth: root.windowControlsHeight
                                        baseHeight: root.windowControlsHeight
                                        buttonRadius: Appearance.rounding.full
                                        contentItem: MaterialSymbol {
                                            anchors.centerIn: parent
                                            horizontalAlignment: Text.AlignHCenter
                                            text: "close"
                                            iconSize: Appearance.font.pixelSize.normal
                                            color: Appearance.m3colors.m3onSurface
                                        }
                                        onClicked: { windowButton.modelData?.close() }
                                    }
                                }
                                Item {
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    implicitHeight: screencopyView.height
                                    implicitWidth: screencopyView.width
                                    ScreencopyView {
                                        id: screencopyView
                                        anchors.centerIn: parent
                                        captureSource: windowButton.modelData
                                        live: true
                                        paintCursor: true
                                        constraintSize: Qt.size(root.maxWindowPreviewWidth, root.maxWindowPreviewHeight)
                                        layer.enabled: true
                                        layer.effect: OpacityMask {
                                            maskSource: Rectangle {
                                                width: screencopyView.width
                                                height: screencopyView.height
                                                radius: Appearance.rounding.small
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // ── Context menu popup ───────────────────────────────────────────────────

    PopupWindow {
        id: contextMenuPopup
        property bool show: false
        property bool menuHovered: contextMenuHoverHandler.hovered

        HoverHandler {
            id: contextMenuHoverHandler
            // Tracks hover for the entire popup window area
        }

        anchor {
            window: root.QsWindow.window
            adjustment: PopupAdjustment.None
            gravity: Edges.Top | Edges.Right
            edges: Edges.Top | Edges.Left
        }

        visible: menuCard.opacity > 0
        color: "transparent"
        implicitWidth: root.QsWindow.window?.width ?? 1
        implicitHeight: menuCard.implicitHeight + 6

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.AllButtons
            onPressed: function(event) {
                const pos = mapToItem(menuCard, event.x, event.y)
                if (pos.x >= 0 && pos.x <= menuCard.width && pos.y >= 0 && pos.y <= menuCard.height)
                    event.accepted = false
                else
                    contextMenuPopup.show = false
            }
        }

        StyledRectangularShadow {
            target: menuCard
            opacity: contextMenuPopup.show ? 1 : 0
            visible: opacity > 0
            Behavior on opacity { animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this) }
        }

        Rectangle {
            id: menuCard

            opacity: contextMenuPopup.show ? 1 : 0
            visible: opacity > 0
            Behavior on opacity { animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this) }

            anchors.bottom: parent.bottom
            anchors.bottomMargin: 0
            x: Math.max(4, Math.min(root.contextMenuCenterX - width / 2,
                                    (root.QsWindow.window?.width ?? width) - width - 4))

            color: Appearance.m3colors.m3surfaceContainer
            border.width: 1
            border.color: Appearance.colors.colLayer0Border
            radius: Appearance.rounding.normal
            clip: true

            implicitWidth: 172
            implicitHeight: menuColumn.implicitHeight + 8

            ColumnLayout {
                id: menuColumn
                anchors.centerIn: parent
                width: parent.implicitWidth - 8
                spacing: 2

                // ── Open ──────────────────────────────────────────────────
                RippleButton {
                    Layout.fillWidth: true
                    implicitHeight: 40
                    buttonRadius: Appearance.rounding.small
                    onClicked: {
                        const appId = root.contextMenuApp?.appId ?? ""
                        contextMenuPopup.show = false
                        DesktopEntries.heuristicLookup(appId)?.execute()
                    }
                    Row {
                        anchors.left: parent.left
                        anchors.leftMargin: 14
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 10
                        MaterialSymbol {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "launch"
                            iconSize: Appearance.font.pixelSize.larger
                            color: Appearance.m3colors.m3onSurface
                        }
                        StyledText {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "Open"
                            color: Appearance.m3colors.m3onSurface
                        }
                    }
                }

                // ── Close / Close all ──────────────────────────────────────
                RippleButton {
                    Layout.fillWidth: true
                    implicitHeight: 40
                    visible: (root.contextMenuApp?.toplevels?.length ?? 0) > 0
                    buttonRadius: Appearance.rounding.small
                    onClicked: {
                        const toplevels = root.contextMenuApp?.toplevels ?? []
                        contextMenuPopup.show = false
                        toplevels.forEach(function(t) { t.close() })
                    }
                    Row {
                        anchors.left: parent.left
                        anchors.leftMargin: 14
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 10
                        MaterialSymbol {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "cancel"
                            iconSize: Appearance.font.pixelSize.larger
                            color: Appearance.m3colors.m3onSurface
                        }
                        StyledText {
                            anchors.verticalCenter: parent.verticalCenter
                            text: (root.contextMenuApp?.toplevels?.length ?? 0) > 1 ? "Close all" : "Close"
                            color: Appearance.m3colors.m3onSurface
                        }
                    }
                }

                // ── Divider ────────────────────────────────────────────────
                Rectangle {
                    Layout.fillWidth: true
                    Layout.leftMargin: 6
                    Layout.rightMargin: 6
                    implicitHeight: 1
                    color: Appearance.colors.colOutlineVariant
                }

                // ── Pin / Unpin ────────────────────────────────────────────
                RippleButton {
                    Layout.fillWidth: true
                    implicitHeight: 40
                    buttonRadius: Appearance.rounding.small
                    onClicked: {
                        const appId = root.contextMenuApp?.appId
                        contextMenuPopup.show = false
                        if (appId) TaskbarApps.togglePin(appId)
                    }
                    Row {
                        anchors.left: parent.left
                        anchors.leftMargin: 14
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 10
                        MaterialSymbol {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "push_pin"
                            iconSize: Appearance.font.pixelSize.larger
                            color: Appearance.m3colors.m3onSurface
                        }
                        StyledText {
                            anchors.verticalCenter: parent.verticalCenter
                            text: root.contextMenuApp?.pinned ? "Unpin" : "Pin"
                            color: Appearance.m3colors.m3onSurface
                        }
                    }
                }
            }
        }
    }
}
