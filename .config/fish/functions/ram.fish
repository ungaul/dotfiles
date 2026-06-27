function ram --description 'Top 20 processes by memory usage'
    ps -eo user,pid,%cpu,rss,comm --sort=-rss | awk 'NR==1{printf "%-10s %8s %5s %8s %s\n","USER","PID","%CPU","MEM","COMMAND"; next} {printf "%-10s %8s %5s %8.1fM %s\n",$1,$2,$3,$4/1024,$5}' | head -20
end
