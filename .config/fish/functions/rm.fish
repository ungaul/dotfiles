function rm --wraps=trash-put --description 'rm alias that sends files to the trash instead of deleting them'
    trash-put $argv
end
