-- Native window title bars via the hyprbars plugin (installed through hyprpm).
-- `hyprpm enable hyprbars` to enable it; `hyprpm reload -n` in execs.lua loads it
-- on every Hyprland start. Guarded since hl.plugin.hyprbars only exists once the
-- plugin is actually loaded into the running instance.

-- Quickshell toggles `enabled` at runtime when switching panel families, but a
-- plain `hyprctl reload` re-runs this file and would otherwise always reset it
-- to a hardcoded default — hiding the bars in Waffle until the next family
-- switch. Read quickshell's persisted state instead, so reload matches reality.
local function is_waffle_active()
    local f = io.open(HOME .. "/.config/illogical-impulse/config.json", "r")
    if f == nil then return false end
    local content = f:read("*a")
    io.close(f)
    return content:find('"panelFamily"%s*:%s*"waffle"') ~= nil
end

if hl.plugin.hyprbars ~= nil then
    hl.config({
        plugin = {
            hyprbars = {
                enabled = is_waffle_active(),
                bar_color = "rgba(1c1c1cff)",
                bar_height = 36,
                bar_text_size = 14,
                bar_text_font = "Google Sans",
                bar_text_align = "left",
                bar_buttons_alignment = "right",
                bar_padding = 24,
                bar_button_padding = 10,
                bar_part_of_window = true, -- border wraps bar+window as one container, not each separately
                on_double_click = HOME .. "/.config/hypr/hyprland/scripts/maximize-active.sh",
            },
        },
    })

    -- Buttons are declared edge-first: the first add_button ends up closest to the
    -- screen edge (rightmost, since bar_buttons_alignment is "right"), and each
    -- subsequent one is placed further left. No maximize button — double-clicking
    -- the bar already maximizes (on_double_click above). Close first, minimize last.
    hl.plugin.hyprbars.add_button({
        bg_color = "rgb(ff4040)",
        fg_color = "rgb(ffffff)",
        size = 16,
        icon = "×",
        action = "hyprctl dispatch \"hl.dsp.window.close()\"",
    })

    hl.plugin.hyprbars.add_button({
        bg_color = "rgb(ffbd2e)",
        fg_color = "rgb(996f00)",
        size = 18,
        icon = "−",
        action = HOME .. "/.config/hypr/hyprland/scripts/minimize-active.sh",
    })
end
