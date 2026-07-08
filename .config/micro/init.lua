local micro = import("micro")
local config = import("micro/config")

function smartCtrlX(bp)
    if bp.Cursor:HasSelection() then
        bp:Cut()   -- coupe la sélection
        return true
    else
        bp:Quit()  -- ferme le buffer (demande si non sauvegardé)
        return true
    end
end

function init()
    config.TryBindKey("Ctrl-x", "lua:initlua.smartCtrlX", true)
end
