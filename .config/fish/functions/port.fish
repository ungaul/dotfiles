function port --description 'List process listening on a given port'
    lsof -i :"$argv[1]"
end
