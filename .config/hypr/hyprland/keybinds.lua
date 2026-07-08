
require("hyprland.lib")
require("hyprland.variables")

local qsScripts = "$HOME/.config/quickshell/$qsConfig/scripts"
local hyprScripts = "$HOME/.config/hypr/hyprland/scripts"
local qsIpcCall = "qs -c $qsConfig ipc call"
local qsIsAlive = qsIpcCall .. " TEST_ALIVE"

hl.bind("CTRL + SUPER + H", hl.dsp.exec_cmd("xdg-open ~/.config/hypr"), { description = "Edit shell config" })
hl.bind("CTRL + SUPER + Escape", hl.dsp.exec_cmd("~/.config/hypr/hyprland/scripts/launch_first_available.sh 'gnome-system-monitor' 'plasma-systemmonitor --page-name Processes' 'command -v btop && kitty -1 fish -c btop'"), { description = "Task manager" })
-- idea (not applied, needs double-press to actually switch): only switch the active device's
-- layout instead of syncing all keyboards, so each keeps/uses its own layout automatically:
-- device=$(hyprctl devices -j | jq -r '.keyboards[] | select(.main==true) | .name'); hyprctl switchxkblayout $device next
hl.bind("SUPER + Space", hl.dsp.exec_cmd("switch=$(hyprctl devices -j | jq -r '.keyboards[] | .active_keymap' | uniq -c | [ $(wc -l) -eq 1 ] && echo 'next' || echo '0'); for device in $(hyprctl devices -j | jq -r '.keyboards[] | .name'); do hyprctl switchxkblayout $device $switch; done"), { description = "Switch Keyboard Layouts" })
hl.bind("SUPER + P", hl.dsp.exec_cmd("bash -c 'F=/tmp/screen_dimmed; H=\"HYPRLAND_INSTANCE_SIGNATURE=$(ls /run/user/1000/hypr/ | tail -1) XDG_RUNTIME_DIR=/run/user/1000 hyprctl\"; [ -f \"$F\" ] && eval \"$H hyprsunset gamma 100\" && rm \"$F\" || (eval \"$H hyprsunset gamma 0\" && touch \"$F\")'"))
hl.bind("CTRL + SUPER + K", hl.dsp.exec_cmd("qs -c ii ipc call osdKeyboard toggle"), { description = "Toggle keyboard chattering fix" })
hl.bind("CTRL + SUPER + A", hl.dsp.exec_cmd(qsIpcCall .. " audio cycleProfile"), { description = "Audio: Cycle output profile (analog/HDMI)", locked = true })
hl.bind("SUPER + Semicolon", hl.dsp.global("quickshell:overviewEmojiToggle"))
hl.bind("SUPER + H", hl.dsp.global("quickshell:cheatsheetToggle"), { description = "Shell: Toggle cheatsheet" })



hl.bind("SUPER + SUPER_L", hl.dsp.global("quickshell:searchToggleRelease"), { description = "Shell: Toggle search" })
hl.bind("SUPER + SUPER_R", hl.dsp.global("quickshell:searchToggleRelease"))

hl.bind("SUPER_L", hl.dsp.global("quickshell:workspaceNumber"),{ ignore_mods = true, transparent = true })
hl.bind("SUPER_R", hl.dsp.global("quickshell:workspaceNumber"),{ ignore_mods = true, transparent = true })
hl.bind("SUPER_L", hl.dsp.global("quickshell:workspaceNumber"),{ ignore_mods = true, transparent = true, release = true })
hl.bind("SUPER_R", hl.dsp.global("quickshell:workspaceNumber"),{ ignore_mods = true, transparent = true, release = true })
hl.bind("SUPER + Tab", hl.dsp.global("quickshell:overviewWorkspacesToggle"), { description = "Shell: Toggle overview" })
hl.bind("SUPER + V", hl.dsp.global("quickshell:overviewClipboardToggle"))
hl.bind("SUPER + Period", hl.dsp.global("quickshell:overviewEmojiToggle"))
hl.bind("SUPER + N", hl.dsp.global("quickshell:sidebarRightToggle"),{ description = "Shell: Toggle right sidebar" })
hl.bind("SUPER + B", hl.dsp.global("quickshell:sidebarLeftToggle"),{ description = "Shell: Toggle left sidebar" })
hl.bind("SUPER + Slash", hl.dsp.global("quickshell:cheatsheetToggle"),{ description = "Shell: Toggle cheatsheet" })
hl.bind("SUPER + K", hl.dsp.global("quickshell:oskToggle"),{ description = "Shell: Toggle on-screen keyboard" })
hl.bind("SUPER + M", hl.dsp.global("quickshell:mediaControlsToggle"),{ description = "Shell: Toggle media controls" })
hl.bind("SUPER + G", hl.dsp.global("quickshell:overlayToggle"),{ description = "Shell: Toggle widget overlay" })
hl.bind("CTRL + ALT + Delete", hl.dsp.global("quickshell:sessionToggle"),{ description = "Shell: Toggle session menu" })
hl.bind("SUPER + J", hl.dsp.global("quickshell:barToggle"),{ description = "Shell: Toggle bar" })
hl.bind("CTRL + ALT + Delete", hl.dsp.exec_cmd(qsIsAlive .. " || pkill wlogout || wlogout -p layer-shell"))

hl.bind("ALT + Alt_L", hl.dsp.global("quickshell:altTabConfirm"), { release = true, non_consuming = true })
hl.bind("ALT + Tab", hl.dsp.global("quickshell:altTabNext"))
hl.bind("ALT + SHIFT + Tab", hl.dsp.global("quickshell:altTabPrev"))


hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd(qsIpcCall .. " brightness increment || brightnessctl s 5%+"),{ locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd(qsIpcCall .. " brightness decrement || brightnessctl s 5%-"),{ locked = true, repeating = true })
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 2%+ -l 1.5"),{ locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 2%-"),{ locked = true, repeating = true })
hl.bind("CTRL + SUPER + R", hl.dsp.exec_cmd("killall ydotool qs quickshell; qs -c $qsConfig &"),{ description = "Shell: Restart widgets" })
hl.bind("CTRL + SUPER + P", hl.dsp.global("quickshell:panelFamilyCycle"), { description = "Shell: Cycle panel family" })
hl.bind("CTRL + SUPER + Y", hl.dsp.global("quickshell:windowedModeToggle"), { description = "Shell: Toggle windowed (floating) mode" })

-- #/# bind = SUPER, Scroll ↑/↓,, -- Focus left/right
for i = 1, 4 do
    local key = { "SUPER + mouse_up", "SUPER + mouse_down" }
    local keycombos = { key[1], key[2], "CTRL + " .. key[1], "CTRL + " .. key[2] }
    local prefix = { "+", "-", "r+", "r-" }
    hl.bind(keycombos[i], hl.dsp.focus({ workspace = prefix[i] .. "1" }))
end

-- #/# bind = CTRL+SUPER, ←/→,, -- Focus left/right
-- #/# bind = CTRL+SUPER+ALT, ←/→,, -- # [hidden] Focus busy left/right
for i = 1, 2 do
    local keys = { "Left", "Right" }
    local prefix = { "r-", "r+" }
    local descdir = { "left", "right" }
    hl.bind("CTRL + SUPER + " .. keys[i], hl.dsp.focus({ workspace = prefix[i] .. "1" }), {description = "Workspace: Focus " .. descdir[i]})
end

--##! Utilities
--# Screenshot, Record, OCR, Color picker, Clipboard history
hl.bind("SUPER + V",hl.dsp.exec_cmd(qsIsAlive .. " || pkill fuzzel || cliphist list | fuzzel --match-mode fzf --dmenu | cliphist decode | wl-copy"),{ description = "Utilities: Clipboard history >> clipboard" })
hl.bind("SUPER + Period",hl.dsp.exec_cmd(qsIsAlive .. " || pkill fuzzel || " .. hyprScripts .. "/fuzzel-emoji.sh copy"),{ description = "Utilities: Emoji >> clipboard" })
hl.bind("SUPER + SHIFT + S",hl.dsp.global("quickshell:regionScreenshot"), { description = "Utilities: Screen snip" })
hl.bind("SUPER + SHIFT + S",hl.dsp.exec_cmd(qsIsAlive .. " || pidof slurp || hyprshot --freeze --clipboard-only --mode region --silent"))
hl.bind("SUPER + SHIFT + A", hl.dsp.global("quickshell:regionSearch"), { description = "Utilities: Google Lens" })
hl.bind("SUPER + SHIFT + A", hl.dsp.exec_cmd(qsIsAlive .. " || pidof slurp || " .. hyprScripts .. "/snip_to_search.sh"))

--##! Screen
--# Zoom
local function zoomfunction(value)
    local zoomvalue = hl.get_config("cursor:zoom_factor")
    if (zoomvalue + value) > 3.0 then
        hl.config({ cursor = { zoom_factor = 3.0 } })
    elseif (zoomvalue + value) < 1.0 then
        hl.config({ cursor = { zoom_factor = 1.0 } })
    else
        hl.config({ cursor = { zoom_factor = zoomvalue + value } })
    end
end
hl.bind("SUPER + parenright", function() zoomfunction(-0.3) end, { repeating = true, description = "Screen: Zoom out" })
hl.bind("SUPER + Equal", function() zoomfunction(0.3) end, { repeating = true, description = "Screen: Zoom in" })

--##! Media
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_SINK@ toggle"), { locked = true })
hl.bind("SUPER + DOWN", hl.dsp.exec_cmd("playerctl play-pause"))
hl.bind("SUPER + LEFT", hl.dsp.exec_cmd("playerctl previous"))
hl.bind("SUPER + RIGHT", hl.dsp.exec_cmd("playerctl next"))

--#!
--##! Window
--# Focusing
hl.bind("SUPER + mouse:272", hl.dsp.window.drag(), { mouse = true, description = "Window: Move" })
hl.bind("SUPER + mouse:273", hl.dsp.window.resize(), { mouse = true, description = "Window: Resize" })

hl.bind("ALT + F4", hl.dsp.window.close(), { description = "Window: Close" })
hl.bind("SUPER + Q", hl.dsp.window.close(), { description = "Window: Close" })
hl.bind("SUPER + SHIFT + Q", hl.dsp.exec_cmd("hyprctl kill"), { description = "Window: Forcefully zap a window" })

--# Positioning mode
hl.bind("SUPER + SHIFT + Space", hl.dsp.window.float({ action = "toggle" }), { description = "Window: Float/Tile" })
hl.bind("SUPER + D", hl.dsp.window.fullscreen({ mode = "maximized", action = "toggle" }),{ description = "Window: Maximize" })
hl.bind("SUPER + F", hl.dsp.window.fullscreen({ mode = "fullscreen", action = "toggle" }),{ description = "Window: Fullscreen" })
hl.bind("SUPER + O", hl.dsp.window.pin(), { description = "Window: Pin" })

--# #/# bind = SUPER+SHIFT, Scroll ↑/↓,, -- Send to workspace left/right
for i = 1, 4 do
    local key = { "SUPER + SHIFT + mouse_", "SUPER + ALT + mouse_" }
    local keycombos = { key[1] .. "down", key[1] .. "up", key[2] .. "down", key[2] .. "up" }
    local prefix = { "r-", "r+", "r-", "r+" }
    hl.bind(keycombos[i], hl.dsp.window.move({ workspace = prefix[i] .. "1" }))
end

--#/# bind = SUPER+SHIFT, ←/→,, -- Send window to workspace -1/+1
for i = 1, 2 do
    local keys = { "Left", "Right" }
    local prefix = { "r-", "r+" }
    local descdir = { "left", "right" }
    hl.bind("SUPER + SHIFT + " .. keys[i], hl.dsp.window.move({ workspace = prefix[i] .. "1" }),
        { description = "Window: Send to workspace " .. descdir[i] })
end

--##! Workspace
--# Switching
--#/# bind = SUPER, Hash,, -- Focus workspace -- (1, 2, 3,...)
for i = 1, 10 do
    hl.bind("SUPER + " .. (i % 10), function()
        hl.dispatch(hl.dsp.focus({ workspace = workspace_in_group(i) }))
    end)
end
for i = 1, 10 do
    local numberkey = { 10, 11, 12, 13, 14, 15, 16, 17, 18, 19 }
    hl.bind("SUPER + code:" .. numberkey[i], function()
        hl.dispatch(hl.dsp.focus({ workspace = workspace_in_group(i) }))
    end)
end
for i = 1, 10 do
    local numpadkey = { 87, 88, 89, 83, 84, 85, 79, 80, 81, 90 }
    hl.bind("SUPER + code:" .. numpadkey[i], function()
        hl.dispatch(hl.dsp.focus({ workspace = workspace_in_group(i) }))
    end)
end

--##! Session
hl.bind("SUPER + L", hl.dsp.exec_cmd("hyprlock"), { locked = true }) -- Sleep
-- hl.bind("switch:on:Lid Switch", hl.dsp.exec_cmd("systemctl suspend || loginctl suspend"), {locked = true} ) -- # [hidden] Suspend when laptop lid is closed, uncomment if for whatever reason it's not the default behavior

--##! Apps
hl.bind("SUPER + T", hl.dsp.exec_cmd(terminal))
hl.bind("SUPER + E", hl.dsp.exec_cmd(fileManager), { description = "App: File manager" })
hl.bind("SUPER + W", hl.dsp.exec_cmd(browser), { description = "App: Browser" })
hl.bind("SUPER + C", hl.dsp.exec_cmd(codeEditor), { description = "App: Code editor" })
hl.bind("SUPER + X", hl.dsp.exec_cmd(textEditor), { description = "App: Text editor" })
hl.bind("CTRL + SUPER + V", hl.dsp.exec_cmd(volumeMixer), { description = "App: Volume mixer" })
hl.bind("SUPER + I", hl.dsp.exec_cmd(settingsApp), { description = "App: Settings app" })
hl.bind("CTRL + SHIFT + Escape", hl.dsp.exec_cmd(taskManager), { description = "App: Task manager" })

--# Cursed stuff
--## Make window not amogus large
-- hl.bind("CTRL + SUPER + Backslash", hl.dsp.window.resize({ x = 640, y = 480, "exact" }))
-- for i = 1, 2 do
--     local keys = { "Left", "Right" }
--     local prefix = { "m-", "m+" }
--     hl.bind("CTRL + SUPER + ALT + " .. keys[i], hl.dsp.focus({ workspace = prefix[i] .. "1" }))
-- end
--#/# bind = SUPER, Page_↑/↓,, -- Focus left/right
-- for i = 1, 4 do
--     local key = { "SUPER + Page_Down", "SUPER + Page_Up" }
--     local keycombos = { key[1], key[2], "CTRL + " .. key[1], "CTRL + " .. key[2] }
--     local prefix = { "r+", "r-", "r+", "r-" }
--     hl.bind(keycombos[i], hl.dsp.focus({ workspace = prefix[i] .. "1" }))
-- end

--## Special
-- hl.bind("SUPER + S", hl.dsp.workspace.toggle_special("special"), { description = "Workspace: Toggle scratchpad" })
-- hl.bind("SUPER + mouse:275", hl.dsp.workspace.toggle_special("special"))
-- for i = 1, 4 do
--     local key = { "BracketLeft", "BracketRight", "Up", "Down" }
--     local prefix = { "-1", "+1", "r-5", "r+5" }
--     hl.bind("CTRL + SUPER + " .. key[i], hl.dsp.focus({ workspace = prefix[i] }))
-- end

--##! Virtual machines
-- hl.define_submap("virtual-machine", function()
--     hl.bind("SUPER + ALT + F1", function()
--         local currentsubmap = hl.get_current_submap()
--         if currentsubmap == "virtual-machine" then
--             hl.dispatch(hl.dsp.exec_cmd(
--                 "notify-send 'Exited Virtual Machine submap' 'Keybinds re-enabled' -a 'Hyprland'"))
--             hl.dispatch(hl.dsp.submap("reset"))
--         elseif currentsubmap == "" then
--             hl.dispatch(hl.dsp.exec_cmd(
--                 "notify-send 'Entered Virtual Machine submap' 'Keybinds disabled. hit SUPER+ALT+F1 to escape' -a 'Hyprland'"))
--             hl.dispatch(hl.dsp.submap("virtual-machine"))
--         end
--     end, { submap_universal = true })
-- end)

--#!
--# Testing
-- hl.bind("SUPER + ALT + F11",
--     hl.dsp.exec_cmd(
--         "bash -c 'RANDOM_IMAGE=$(find ~/Pictures -type f | shuf -n 1); ACTION=$(notify-send \"Test notification with body image\" \"This notification should contain your user account <b>image</b> and <a href=\\\"https://discord.com/app\\\">Discord</a> <b>icon</b>. Oh and here is a random image in your Pictures folder: <img src=\\\"$RANDOM_IMAGE\\\" alt=\\\"Testing image\\\"/>\" -a \"Hyprland\" -p -h \"string:image-path:/var/lib/AccountsService/icons/$USER\" -t 6000 -i \"discord\" -A \"openImage=Profile image\" -A \"action2=Open the random image\" -A \"action3=Useless button\"); [[ $ACTION == *openImage ]] && xdg-open \"/var/lib/AccountsService/icons/$USER\"; [[ $ACTION == *action2 ]] && xdg-open \"$RANDOM_IMAGE\"'")
-- ) -- # [hidden]
-- hl.bind("SUPER + ALT + F12",
--     hl.dsp.exec_cmd(
--         "bash -c 'RANDOM_IMAGE=$(find ~/Pictures -type f | shuf -n 1); ACTION=$(notify-send \"Test notification\" \"This notification should contain a random image in your <b>Pictures</b> folder and <a href=\\\"https://discord.com/app\\\">Discord</a> <b>icon</b>.\n<i>Flick right to dismiss!</i>\" -a \"Discord (fake)\" -p -h \"string:image-path:$RANDOM_IMAGE\" -t 6000 -i \"discord\" -A \"openImage=Profile image\" -A \"action2=Useless button\"); [[ $ACTION == *openImage ]] && xdg-open \"/var/lib/AccountsService/icons/$USER\"'")
-- )                                                                                                        -- # [hidden]
-- hl.bind("SUPER + ALT + Equal",
--     hl.dsp.exec_cmd("notify-send 'Urgent notification' 'Ah hell no' -u critical -a 'Hyprland keybind'")) -- # [hidden]
--#/# bind = SUPER+SHIFT, Page_↑/↓,, -- Send to workspace left/right
-- for i = 1, 2 do
--     local keydirs = { "Up", "Down" }
--     local prefix = { "r-", "r+" }
--     local descdir = { "left", "right" }
--     hl.bind("SUPER + SHIFT + Page_" .. keydirs[i], hl.dsp.window.move({ workspace = prefix[i] .. "1" }), {description = "Window: Send to workspace " .. descdir[i]})
-- end
-- for i = 1, 4 do
--     local key = { "SUPER + ALT + Page_", "CTRL + SUPER + SHIFT + " }
--     local keycombos = { key[1] .. "down", key[1] .. "up", key[2] .. "Right", key[2] .. "Left" }
--     local prefix = { "r+", "r-", "r+", "r-" }
--     hl.bind(keycombos[i], hl.dsp.window.move({ workspace = prefix[i] .. "1" })) -- # [hidden]
-- end

-- hl.bind("SUPER + ALT + S",
--     hl.dsp.window.move({ workspace = "special:special", follow = false }), { description = "Window: Send to scratchpad" })
-- hl.bind("CTRL + SUPER + S", hl.dsp.workspace.toggle_special("special"))

--#/# bind = SUPER + ←/↑/→/↓,, -- Focus in direction
-- for i = 1, 4 do
--     local arrowkey = { "Left", "Right", "Up", "Down" }
--     local focusdir = { "l", "r", "u", "d" }
--     hl.bind("SUPER + " .. arrowkey[i], hl.dsp.focus({ direction = focusdir[i] }),
--         { description = "Window: Focus " .. arrowkey[i] })
-- end
-- for i = 1, 2 do
--     local arrowkey = { "BracketLeft", "BracketRight" }
--     local focusdir = { "l", "r" }
--     hl.bind("SUPER + " .. arrowkey[i], hl.dsp.focus({ direction = focusdir[i] }))
-- end
--#/# bind = SUPER + SHIFT, ←/↑/→/↓,, -- Move in direction
-- for i = 1, 4 do
--     local arrowkey = { "Left", "Right", "Up", "Down" }
--     local focusdir = { "l", "r", "u", "d" }
--     hl.bind("SUPER + SHIFT + " .. arrowkey[i], hl.dsp.window.move({ direction = focusdir[i] }),
--         { description = "Window: Move " .. arrowkey[i] })
-- end

--#/# bind = SUPER+ALT, Hash,, -- Send to workspace -- (1, 2, 3,...)
-- for i = 1, 10 do
--     hl.bind("SUPER + ALT + " .. (i % 10), function()
--         hl.dispatch(hl.dsp.window.move({ workspace = workspace_in_group(i), follow = false }))
--     end)
-- end
-- for i = 1, 10 do
--     local numpadkey = { 87, 88, 89, 83, 84, 85, 79, 80, 81, 90 }
--     hl.bind("SUPER + ALT + code:" .. numpadkey[i], function()
--         hl.dispatch(hl.dsp.window.move({ workspace = workspace_in_group(i), follow = false }))
--     end)
-- end
--# OCR
-- hl.bind("SUPER + SHIFT + X", hl.dsp.global("quickshell:regionOcr"),
--     { description = "Utilities: Character recognition >> clipboard" })
--# Color picker
-- hl.bind("SUPER + SHIFT + C", hl.dsp.exec_cmd("hyprpicker -a"),
--     { description = "Utilities: Pick color #RRGGBB >> clipboard" })
