pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import qs
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import Qt5Compat.GraphicalEffects

Scope {
    id: root

    readonly property int itemW: 220
    readonly property int itemH: 150
    readonly property int iconSize: 28
    readonly property int iconPad: 6
    readonly property int itemPad: 10
    readonly property int itemSpacing: 8

    readonly property var sortedToplevels: ToplevelManager.toplevels.values.filter(t => {
        return HyprlandData.clientForToplevel(t) !== null;
    }).sort((a, b) => {
        const ca = HyprlandData.clientForToplevel(a);
        const cb = HyprlandData.clientForToplevel(b);
        const wsDiff = (ca?.workspace?.id ?? 0) - (cb?.workspace?.id ?? 0);
        if (wsDiff !== 0) return wsDiff;
        return (ca?.at?.[0] ?? 0) - (cb?.at?.[0] ?? 0);
    })

    // Like Windows' Alt-Tab: the currently active window is always sorted to the
    // end, so the first card is always a different window, never the current one.
    readonly property var toplevels: {
        const active = ToplevelManager.activeToplevel;
        const idx = root.sortedToplevels.indexOf(active);
        if (idx === -1) return root.sortedToplevels;
        const rotated = root.sortedToplevels.slice();
        const [current] = rotated.splice(idx, 1);
        rotated.push(current);
        return rotated;
    }

    function cycleNext() {
        if (toplevels.length === 0) return;
        if (!GlobalStates.altTabOpen) {
            GlobalStates.altTabIndex = 0;
            GlobalStates.altTabOpen = true;
            return;
        }
        GlobalStates.altTabIndex = (GlobalStates.altTabIndex + 1) % toplevels.length;
    }

    function cyclePrev() {
        if (toplevels.length === 0) return;
        if (!GlobalStates.altTabOpen) {
            GlobalStates.altTabIndex = (toplevels.length - 2 + toplevels.length) % toplevels.length;
            GlobalStates.altTabOpen = true;
            return;
        }
        GlobalStates.altTabIndex = (GlobalStates.altTabIndex - 1 + toplevels.length) % toplevels.length;
    }

    function confirm() {
        if (!GlobalStates.altTabOpen) return;
        GlobalStates.altTabOpen = false;
        const t = root.toplevels[GlobalStates.altTabIndex];
        if (t) {
            const c = HyprlandData.clientForToplevel(t);
            if (c) {
                // Focus alone doesn't guarantee the window is raised above others
                // in the stack (notably for floating windows in waffle mode), so
                // explicitly bring it to the top of the z-order too.
                Hyprland.dispatch(`hl.dsp.focus({ window = "address:${c.address}" })`);
                Hyprland.dispatch(`hl.dsp.window.bring_to_top({ window = "address:${c.address}" })`);
            }
        }
    }

    // Cycle forward
    GlobalShortcut {
        name: "altTabNext"
        description: "Alt+Tab: open switcher / cycle forward"
        onPressed: root.cycleNext()
    }

    // Cycle backward
    GlobalShortcut {
        name: "altTabPrev"
        description: "Alt+Shift+Tab: cycle backward"
        onPressed: root.cyclePrev()
    }

    // Hyprland bind (Lua): use { release = true } so it fires ON key release.
    // With release=true, Hyprland fires shortcut_activated (onPressed) when Alt_L is released.
    // hl.bind("ALT + Alt_L", hl.dsp.global("quickshell:altTabConfirm"), { release = true, non_consuming = true })
    GlobalShortcut {
        name: "altTabConfirm"
        description: "Confirm alt-tab when Alt is released"
        onPressed: root.confirm()
    }


    PanelWindow {
        id: win
        visible: GlobalStates.altTabOpen
        color: "transparent"

        WlrLayershell.namespace: "quickshell:alttab"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: GlobalStates.altTabOpen ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

        anchors { top: true; bottom: true; left: true; right: true }

        FocusScope {
            id: focusScope
            anchors.fill: parent
            focus: true

            Keys.onPressed: event => {
                if (event.key === Qt.Key_Left || event.key === Qt.Key_Up) {
                    root.cyclePrev(); event.accepted = true;
                } else if (event.key === Qt.Key_Right || event.key === Qt.Key_Down) {
                    root.cycleNext(); event.accepted = true;
                } else if (event.key === Qt.Key_Tab) {
                    root.cycleNext(); event.accepted = true;
                } else if (event.key === Qt.Key_Backtab) {
                    root.cyclePrev(); event.accepted = true;
                } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                    root.confirm(); event.accepted = true;
                } else if (event.key === Qt.Key_Escape) {
                    GlobalStates.altTabOpen = false; event.accepted = true;
                }
            }

            // Fallback: detect Alt release via QML key events
            // (layer surface receives key events when it has OnDemand focus)
            Keys.onReleased: event => {
                if (event.key === Qt.Key_Alt) {
                    root.confirm(); event.accepted = true;
                }
            }

            MouseArea {
                anchors.fill: parent
                onClicked: GlobalStates.altTabOpen = false
            }

            Rectangle {
                id: card
                anchors.centerIn: parent
                color: ColorUtils.transparentize(Appearance.m3colors.m3surfaceContainer, Appearance.backgroundTransparency)
                border.color: Appearance.colors.colOutlineVariant
                border.width: 1
                radius: Appearance.rounding.large

                readonly property int outerPad: 12
                width: Math.min(row.implicitWidth + outerPad * 2, parent.width - 80)
                height: row.implicitHeight + outerPad * 2

                MouseArea { anchors.fill: parent }

                Row {
                    id: row
                    anchors.centerIn: parent
                    spacing: root.itemSpacing

                    Repeater {
                        model: ScriptModel { values: root.toplevels }

                        delegate: Item {
                            id: entry
                            required property int index
                            required property var modelData

                            property var client: HyprlandData.clientForToplevel(entry.modelData)
                            property bool selected: GlobalStates.altTabIndex === entry.index
                            property string iconName: AppSearch.guessIcon(client?.class ?? "")

                            implicitWidth: root.itemW + root.itemPad * 2
                            implicitHeight: root.itemH + root.itemPad * 2 + titleLabel.implicitHeight + 6

                            Rectangle {
                                anchors.fill: parent
                                radius: Appearance.rounding.normal
                                color: entry.selected ? Appearance.colors.colSecondaryContainer : "transparent"
                                border.color: entry.selected ? Appearance.colors.colSecondary : "transparent"
                                border.width: 1
                            }

                            Item {
                                id: previewArea
                                x: root.itemPad
                                y: root.itemPad
                                width: root.itemW
                                height: root.itemH
                                clip: true

                                Rectangle {
                                    anchors.fill: parent
                                    radius: Appearance.rounding.small
                                    color: Appearance.m3colors.m3surfaceContainerHigh
                                }

                                ScreencopyView {
                                    anchors.fill: parent
                                    // Only the selected card needs to actually stream — capturing every
                                    // window live simultaneously is what makes rapid alt-tabbing spike CPU.
                                    // Unselected cards still get a single static frame (one-shot capture).
                                    captureSource: GlobalStates.altTabOpen ? entry.modelData : null
                                    live: entry.selected

                                    // The rounded-corner mask is a per-item offscreen render pass; only
                                    // worth paying for on the selected card, which is rendered larger/in focus.
                                    layer.enabled: entry.selected
                                    layer.effect: OpacityMask {
                                        maskSource: Rectangle {
                                            width: previewArea.width
                                            height: previewArea.height
                                            radius: Appearance.rounding.small
                                        }
                                    }
                                }

                                Item {
                                    x: root.iconPad
                                    y: root.iconPad
                                    width: root.iconSize + root.iconPad * 2
                                    height: root.iconSize + root.iconPad * 2

                                    Rectangle {
                                        anchors.fill: parent
                                        radius: Appearance.rounding.small
                                        color: ColorUtils.transparentize(Appearance.m3colors.m3surfaceContainer, 0.2)
                                    }

                                    Image {
                                        anchors.centerIn: parent
                                        width: root.iconSize
                                        height: root.iconSize
                                        source: Quickshell.iconPath(entry.iconName, "application-x-executable")
                                        sourceSize: Qt.size(root.iconSize, root.iconSize)
                                        smooth: true
                                        mipmap: true
                                        visible: status === Image.Ready
                                    }

                                    MaterialSymbol {
                                        anchors.centerIn: parent
                                        text: "apps"
                                        iconSize: root.iconSize
                                        color: Appearance.colors.colOnSurfaceVariant
                                        visible: parent.children[1].status !== Image.Ready
                                    }
                                }

                                Rectangle {
                                    id: closeButton
                                    x: previewArea.width - width - root.iconPad
                                    y: root.iconPad
                                    width: root.iconSize
                                    height: root.iconSize
                                    radius: width / 2
                                    color: closeMouseArea.containsMouse ? Appearance.colors.colError : ColorUtils.transparentize(Appearance.m3colors.m3surfaceContainer, 0.2)
                                    visible: entry.client !== null
                                    Behavior on color { ColorAnimation { duration: 80 } }

                                    MaterialSymbol {
                                        anchors.centerIn: parent
                                        text: "close"
                                        iconSize: root.iconSize - 12
                                        color: closeMouseArea.containsMouse ? Appearance.colors.colOnError : Appearance.colors.colOnSurfaceVariant
                                    }

                                    MouseArea {
                                        id: closeMouseArea
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: mouse => {
                                            const addr = entry.client?.address;
                                            if (addr) Hyprland.dispatch(`hl.dsp.window.close({ window = "address:${addr}" })`);
                                            mouse.accepted = true;
                                        }
                                    }
                                }
                            }

                            StyledText {
                                id: titleLabel
                                anchors {
                                    top: previewArea.bottom
                                    topMargin: 6
                                    horizontalCenter: parent.horizontalCenter
                                }
                                width: root.itemW
                                text: {
                                    const title = entry.client?.title ?? "";
                                    return title.length > 22 ? title.substring(0, 20) + "…" : title;
                                }
                                font.pixelSize: Appearance.font.pixelSize.smaller
                                color: entry.selected ? Appearance.colors.colOnSecondaryContainer : Appearance.colors.colOnSurfaceVariant
                                horizontalAlignment: Text.AlignHCenter
                                elide: Text.ElideRight
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    GlobalStates.altTabIndex = entry.index;
                                    root.confirm();
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
