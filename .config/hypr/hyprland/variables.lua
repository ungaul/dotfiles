hl.env("qsConfig", "ii")
local home_dir = os.getenv("HOME")
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "auto")
local xdg_data_dirs_old = os.getenv("XDG_DATA_DIRS") or ""
hl.env("XDG_DATA_DIRS", home_dir .. "/.local/share/flatpak/exports/share:/var/lib/flatpak/exports/share:/usr/local/share:/usr/share:" .. xdg_data_dirs_old)
hl.env("QT_QPA_PLATFORM", "wayland;xcb")
hl.env("QT_QPA_PLATFORMTHEME", "kde")
hl.env("XDG_MENU_PREFIX", "plasma-")
hl.env("ILLOGICAL_IMPULSE_VIRTUAL_ENV", home_dir .. "/.local/state/quickshell/.venv")
hl.env("HYPRCURSOR_THEME", "macOS-hypr")
hl.env("HYPRCURSOR_SIZE", "24")


textEditor = "micro"
fileManager = "nautilus"
terminal = "ghostty"
browser = "helium-browser"
codeEditor = "command -v micro && kitty -1 micro"
volumeMixer = "pavucontrol-qt"
settingsApp = "XDG_CURRENT_DESKTOP=gnome ~/.config/hypr/hyprland/scripts/launch_first_available.sh 'qs -p ~/.config/quickshell/$qsConfig/settings.qml' 'systemsettings'"
taskManager = "plasma-systemmonitor --page-name Processes"

workspaceGroupSize = 10
