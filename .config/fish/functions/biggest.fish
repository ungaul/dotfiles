function biggest --description 'Show the 20 biggest files/dirs under current directory'
    du -ah . | sort -rh | head -20
end
