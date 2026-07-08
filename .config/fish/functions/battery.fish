function battery --description 'Show battery percentage, state and time remaining'
    set -l bat (upower -e | grep -i BAT | head -1)
    if test -z "$bat"
        echo "No battery found"
        return 1
    end
    upower -i $bat | grep -E 'state|percentage|time to (empty|full)' | string trim
end
