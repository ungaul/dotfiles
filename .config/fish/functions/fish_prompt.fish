function fish_prompt
    echo -n "[$USER@$hostname:$(prompt_pwd --dir-length=0)]\$ "
end
