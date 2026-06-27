-- monitors.lua
-- Loaded automatically by hyprland.lua if this file exists.
-- Defines monitor layout and cycles displays with XF86TouchpadToggle.

hl.monitor({ output = "eDP-1",   mode = "1920x1080@60", position = "0x0",    scale = 1 })
hl.monitor({ output = "HDMI-A-2", mode = "1920x1080@60", position = "1920x0", scale = 1 })

-- Cycle: both → laptop only → external only → both
local monitorState = "both"

hl.bind("XF86TouchpadToggle", function()
    if monitorState == "both" then
        hl.monitor({ output = "HDMI-A-2", disabled = true })
        monitorState = "laptop"
    elseif monitorState == "laptop" then
        hl.monitor({ output = "eDP-1",    disabled = true })
        hl.monitor({ output = "HDMI-A-2", disabled = false })
        monitorState = "external"
    else
        hl.monitor({ output = "eDP-1",    disabled = false })
        hl.monitor({ output = "HDMI-A-2", disabled = false })
        monitorState = "both"
    end
end, { description = "Monitor: Cycle active display", locked = true })

hl.bind("SUPER + ALT + D", function()
    if monitorState == "both" then
        hl.monitor({ output = "HDMI-A-2", disabled = true })
        monitorState = "laptop"
    elseif monitorState == "laptop" then
        hl.monitor({ output = "eDP-1",    disabled = true })
        hl.monitor({ output = "HDMI-A-2", disabled = false })
        monitorState = "external"
    else
        hl.monitor({ output = "eDP-1",    disabled = false })
        hl.monitor({ output = "HDMI-A-2", disabled = false })
        monitorState = "both"
    end
end, { description = "Monitor: Cycle active display", locked = true })
