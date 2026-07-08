function logs --description 'Follow the system journal, optionally filtered by level (e.g. logs error)'
    if test (count $argv) -gt 0
        set -l level $argv[1]
        if test "$level" = error
            set level err
        end
        journalctl -f -n 100 -p $level
    else
        journalctl -f -n 100
    end
end
