//@ pragma UseQApplication
//@ pragma Env QS_NO_RELOAD_POPUP=1
//@ pragma Env QT_QUICK_CONTROLS_STYLE=Basic
//@ pragma Env QT_QUICK_FLICKABLE_WHEEL_DECELERATION=10000

// Remove two slashes below and adjust the value to change the UI scale
////@ pragma Env QT_SCALE_FACTOR=1

import "modules/common"
import "services"
import "panelFamilies"

import QtQuick
import QtQuick.Window
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

ShellRoot {
    id: root

    // Stuff for every panel family
    ReloadPopup {}

    Component.onCompleted: {
        MaterialThemeLoader.reapplyTheme()
        Hyprsunset.load()
        FirstRunExperience.load()
        ConflictKiller.load()
        Cliphist.refresh()
        Wallpapers.load()
        Updates.load()
    }

    // Only re-sync the idempotent Hyprland rules/toggles here, not the one-shot
    // transition actions (minimizing stray windows, floating pre-existing ones,
    // unmaximizing) — this fires on every quickshell reload/restart, not just on
    // an actual Waffle<->ii switch, and re-running those one-shot actions on a
    // plain reload would re-minimize/re-float windows the user already adjusted.
    Connections {
        target: Config
        function onReadyChanged() {
            if (Config.ready) {
                root.applyHyprlandRules()
            }
        }
    }


    // Panel families
    property list<string> families: ["ii", "waffle"]
    function cyclePanelFamily() {
        const currentIndex = families.indexOf(Config.options.panelFamily)
        const nextIndex = (currentIndex + 1) % families.length
        Config.options.panelFamily = families[nextIndex]
    }

    component PanelFamilyLoader: LazyLoader {
        required property string identifier
        property bool extraCondition: true
        active: Config.ready && Config.options.panelFamily === identifier && extraCondition
    }
    
    PanelFamilyLoader {
        identifier: "ii"
        component: IllogicalImpulseFamily {}
    }

    PanelFamilyLoader {
        identifier: "waffle"
        component: WaffleFamily {}
    }

    // Waffle has no workspace switcher — pinning new windows to waffleWorkspaceId
    // and minimizing stray ones at the moment of the switch only stops windows
    // from accumulating elsewhere; it doesn't stop the user from navigating to
    // another workspace via keybind/scroll/swipe. Continuously snap back to
    // waffleWorkspaceId whenever it's active and the workspace drifts away,
    // regardless of how that happened. Ignore special workspaces (negative ids,
    // e.g. the minimized tray) since landing on one is intentional.
    readonly property int activeWorkspaceId: Hyprland.focusedMonitor?.activeWorkspace?.id ?? 1
    onActiveWorkspaceIdChanged: {
        if (Config.options.panelFamily === "waffle" && root.activeWorkspaceId > 0 && root.activeWorkspaceId !== root.waffleWorkspaceId) {
            Hyprland.dispatch(`hl.dsp.focus({ workspace = ${root.waffleWorkspaceId} })`)
        }
    }

    // hyprbars (native title bars) only make sense in Waffle's floating-window layout
    Process {
        id: hyprbarsToggle
        command: ["hyprctl", "eval", `hl.config({ plugin = { hyprbars = { enabled = ${Config.options.panelFamily === "waffle" ? "true" : "false"} } } })`]
    }

    // One-shot: windows shouldn't start maximized right after switching into
    // Waffle. Only meaningful at the moment of the switch, not on every reload.
    Process {
        id: unmaximizeAllOnWaffle
        command: ["hyprctl", "eval",
            "for _, w in pairs(hl.get_windows()) do\n" +
            "  hl.dispatch(hl.dsp.window.fullscreen({ mode = 'maximized', action = 'unset', window = w }))\n" +
            "end"
        ]
    }

    // The workspace that was active at the moment of switching INTO Waffle —
    // Waffle pins to this one, not hardcoded to 1, since the user can switch
    // from any workspace. Persisted only for the lifetime of the shell process;
    // re-derived fresh on every ii -> waffle transition.
    property int waffleWorkspaceId: 1

    // Idempotent: just ensures the rule exists/matches the current family and
    // pinned workspace. Safe to rerun on every reload. The window_rule handle's
    // set_enabled doesn't reliably support mutating fields like `workspace` in
    // place, so when the pinned workspace changes the old rule is disabled and
    // a fresh one is created targeting the new workspace.
    Process {
        id: singleWorkspaceRuleToggle
        command: ["hyprctl", "eval",
            (Config.options.panelFamily === "waffle"
                ? ("if _waffleWorkspaceRule then _waffleWorkspaceRule:set_enabled(false) end\n" +
                   `_waffleWorkspaceRule = hl.window_rule({ name = 'waffle-workspace-1', match = { class = '.*' }, workspace = '${root.waffleWorkspaceId}' })`)
                : "if _waffleWorkspaceRule then _waffleWorkspaceRule:set_enabled(false) end")
        ]
    }

    // One-shot: Waffle has no workspace switcher and no "Desktops" UI, so don't
    // let windows spread across workspaces there — hide (minimize) any
    // pre-existing window left on another workspace at the moment of the switch.
    // Keeps whatever workspace was active right before the switch, not a
    // hardcoded one. Must NOT rerun on a plain reload, or it'll re-minimize
    // windows the user has since restored.
    Process {
        id: minimizeOtherWorkspaces
        command: ["hyprctl", "eval", `hl.exec_cmd(HOME .. '/.config/hypr/hyprland/scripts/minimize-other-workspaces.sh ${root.waffleWorkspaceId}')`]
    }

    // One-shot: restore every window to tiled layout when leaving Waffle, since
    // ii's layout expects tiled windows, not the floating ones Waffle uses.
    Process {
        id: tileExistingWindows
        command: ["hyprctl", "eval",
            "for _, w in pairs(hl.get_windows()) do\n" +
            "  if w.floating then\n" +
            "    hl.dispatch(hl.dsp.window.float({ action = 'unset', window = w }))\n" +
            "  end\n" +
            "end"
        ]
    }

    // Idempotent: just ensures the rule exists/matches the current family.
    Process {
        id: waffleFloatRuleToggle
        command: ["hyprctl", "eval",
            (Config.options.panelFamily === "waffle"
                ? ("if not _waffleFloatRule then\n" +
                   "  _waffleFloatRule = hl.window_rule({ name = 'waffle-float-all', match = { class = '.*' }, float = true, size = {'(monitor_w*0.6)', '(monitor_h*0.6)'} })\n" +
                   "else\n" +
                   "  _waffleFloatRule:set_enabled(true)\n" +
                   "end")
                : "if _waffleFloatRule then _waffleFloatRule:set_enabled(false) end")
        ]
    }

    // One-shot: float every pre-existing window at the moment of the switch.
    // Windows opened afterwards are floated automatically by the rule above —
    // rerunning this loop on a plain reload is harmless (already-floating
    // windows are skipped) but unnecessary, so it's gated like the others.
    // The waffle-float-all rule's size (monitor_w*0.6 x monitor_h*0.6) only
    // applies when a window is first mapped while the rule is active — toggling
    // an already-existing window into floating does NOT re-trigger it, which is
    // why pre-existing windows were ending up at their old/wrong geometry
    // instead of the configured 60%x60%, centered. So after floating each
    // pre-existing window, explicitly resize (exact pixels, computed from that
    // window's own monitor — multi-monitor safe) and center it to match.
    // Floating itself requires the window to be focused first; resize/center
    // accept an explicit `window` target directly.
    Process {
        id: floatExistingWindows
        command: ["hyprctl", "eval",
            "for _, w in pairs(hl.get_windows()) do\n" +
            "  if not w.floating then\n" +
            "    hl.dispatch(hl.dsp.focus({ window = w }))\n" +
            "    hl.dispatch(hl.dsp.window.float({ action = 'set' }))\n" +
            "  end\n" +
            "  local mw = w.monitor and w.monitor.width or 1920\n" +
            "  local mh = w.monitor and w.monitor.height or 1080\n" +
            "  hl.dispatch(hl.dsp.window.resize({ window = w, x = math.floor(mw * 0.6), y = math.floor(mh * 0.6), params = {'exact'} }))\n" +
            "  hl.dispatch(hl.dsp.window.center({ window = w }))\n" +
            "end"
        ]
    }

    // Waffle is styled after Windows, which doesn't round window corners.
    // Square them off while Waffle is active, restore the normal rounding in ii.
    Process {
        id: waffleSquareCornersToggle
        command: ["hyprctl", "eval",
            (Config.options.panelFamily === "waffle"
                ? ("if not _waffleNoRoundingRule then\n" +
                   "  _waffleNoRoundingRule = hl.window_rule({ name = 'waffle-no-rounding', match = { class = '.*' }, rounding = 0 })\n" +
                   "else\n" +
                   "  _waffleNoRoundingRule:set_enabled(true)\n" +
                   "end")
                : "if _waffleNoRoundingRule then _waffleNoRoundingRule:set_enabled(false) end")
        ]
    }

    // The 1px border is drawn around the window content separately from the
    // hyprbars title bar (bar_part_of_window above merges them visually into one
    // container, but the border itself still renders). Just turn it off in Waffle.
    Process {
        id: waffleNoBorderToggle
        command: ["hyprctl", "eval",
            (Config.options.panelFamily === "waffle"
                ? ("if not _waffleNoBorderRule then\n" +
                   "  _waffleNoBorderRule = hl.window_rule({ name = 'waffle-no-border', match = { class = '.*' }, border_size = 0 })\n" +
                   "else\n" +
                   "  _waffleNoBorderRule:set_enabled(true)\n" +
                   "end")
                : "if _waffleNoBorderRule then _waffleNoBorderRule:set_enabled(false) end")
        ]
    }

    // Alt-Tab's confirm() raises the picked window with hl.dsp.window.bring_to_top,
    // which plays the windowsMove animation — distracting when alt-tabbing through
    // Waffle's stack of overlapping floating windows. Disable it in Waffle only.
    Process {
        id: waffleNoAltTabAnimToggle
        command: ["hyprctl", "eval",
            (Config.options.panelFamily === "waffle"
                ? "hl.animation({ leaf = 'windowsMove', enabled = false })"
                : "hl.animation({ leaf = 'windowsMove', enabled = true, speed = 3, bezier = 'emphasizedDecel', style = 'slide' })")
        ]
    }

    // Windows is edge-to-edge: no gap between floating windows and the screen
    // border in Waffle. Restore the normal outer gap in ii.
    Process {
        id: waffleNoGapsToggle
        command: ["hyprctl", "eval",
            (Config.options.panelFamily === "waffle"
                ? "hl.config({ general = { gaps_out = 0 } })"
                : "hl.config({ general = { gaps_out = 5 } })")
        ]
    }

    // Waffle's floating windows overlap, so hover-to-focus (follow_mouse) makes
    // it too easy to accidentally focus a different window while just moving
    // the cursor across the screen. Require an actual click in Waffle.
    Process {
        id: waffleClickToFocusToggle
        command: ["hyprctl", "eval",
            (Config.options.panelFamily === "waffle"
                ? "hl.config({ input = { follow_mouse = 0 } })"
                : "hl.config({ input = { follow_mouse = 1 } })")
        ]
    }

    // Idempotent rule/toggle sync — safe to rerun on every quickshell reload,
    // since it only ensures Hyprland-side state matches the current family.
    function applyHyprlandRules() {
        hyprbarsToggle.running = true
        singleWorkspaceRuleToggle.running = true
        waffleFloatRuleToggle.running = true
        waffleSquareCornersToggle.running = true
        waffleNoBorderToggle.running = true
        waffleNoAltTabAnimToggle.running = true
        waffleNoGapsToggle.running = true
        waffleClickToFocusToggle.running = true
    }

    // Full transition — includes one-shot actions that should only fire when
    // the family actually changes, not on a plain reload.
    function applyPanelFamilyTransition() {
        if (Config.options.panelFamily === "waffle") {
            // Capture whatever workspace was active right before the switch —
            // not hardcoded to 1 — so Waffle pins to it and only minimizes
            // windows that were elsewhere, never the ones already in view.
            root.waffleWorkspaceId = root.activeWorkspaceId > 0 ? root.activeWorkspaceId : 1
        }
        applyHyprlandRules()
        if (Config.options.panelFamily === "waffle") {
            unmaximizeAllOnWaffle.running = true
            floatExistingWindows.running = true
            minimizeOtherWorkspaces.running = true
        } else {
            tileExistingWindows.running = true
        }
    }

    Connections {
        target: Config.options
        function onPanelFamilyChanged() {
            // Config.ready flips true only after the JSON file is fully loaded
            // (see Config.qml's onLoaded), and panelFamily's initial assignment
            // from disk happens as part of that same load — so it's still false
            // here for the very first (default -> persisted value) change. Only
            // react once the config has actually finished loading, so a plain
            // restart with panelFamily already "waffle" doesn't look like a
            // fresh transition and re-trigger the one-shot actions.
            if (Config.ready) {
                root.applyPanelFamilyTransition()
            }
        }
    }

    // Shortcuts
    IpcHandler {
        target: "panelFamily"

        function cycle(): void {
            root.cyclePanelFamily()
        }
    }

    GlobalShortcut {
        name: "panelFamilyCycle"
        description: "Cycles panel family"

        onPressed: root.cyclePanelFamily()
    }
}

