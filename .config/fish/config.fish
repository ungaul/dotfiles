if status is-interactive
  fastfetch
  set -g fish_greeting ""
end

set -gx TERM xterm-256color
# nnn earthy green/brown theme
# nnn using Alacritty's normal green
set -gx NNN_COLORS '#02020303;2222'

# block char dir exe regular hardlink symlink missing orphan fifo socket other
set -gx NNN_FCOLORS '000002020003080808080300'
set -gx NNN_OPTS 'eH'

if test -d /run/user/1000/hypr
    set -gx HYPRLAND_INSTANCE_SIGNATURE (ls -t /run/user/1000/hypr/ | head -1)
end
# SSH (and other non-graphical logins) don't inherit WAYLAND_DISPLAY from the
# compositor. If this machine actually has a live Wayland session, pick up
# its socket so tools like `qs`/hyprctl work the same over SSH as locally.
if test -z "$WAYLAND_DISPLAY"
    for sock in /run/user/1000/wayland-*
        if test -S $sock
            set -gx WAYLAND_DISPLAY (basename $sock)
            break
        end
    end
end
if test -n "$WAYLAND_DISPLAY"
    set -gx XDG_SESSION_TYPE wayland
else
    set -gx XDG_SESSION_TYPE x11
end
set -gx XDG_RUNTIME_DIR /run/user/1000

# bun
set --export BUN_INSTALL "$HOME/.bun"
set --export PATH $BUN_INSTALL/bin $PATH

# opencode
fish_add_path /home/gaulerie/.opencode/bin
