function sync --description 'yadm sync (dotfiles) + restore crontab/packages'
    bash -c 'cd ~ && grep -vE "^#|^$" .sync | sed -n "/\[blacklist\]/q;p" | xargs -I{} yadm add "$HOME/{}" ; yadm add -u ; yadm commit -m "sync: $(date +%F_%T)" ; yadm pull --rebase ; yadm push && crontab "$HOME/.cron" ; yay -S --needed --noconfirm - < "$HOME/.pacman"'
end
