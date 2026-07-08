function errors --description 'Show error-level journal entries since last boot'
    journalctl -p err -b
end
