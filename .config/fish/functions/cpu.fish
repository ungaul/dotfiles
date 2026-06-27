function cpu --description 'Top 20 processes by CPU usage'
    ps -eo user,pid,%cpu,%mem,comm --sort=-%cpu | head -20
end
