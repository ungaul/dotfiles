function cron --description 'Show cron logs (-f to follow), or -l/-e for crontab -l/-e'
    switch "$argv[1]"
        case -f
            journalctl -u cronie -f
        case -l
            crontab -l
        case -e
            crontab -e
        case '*'
            journalctl -u cronie -n 200 --no-pager
    end
end
