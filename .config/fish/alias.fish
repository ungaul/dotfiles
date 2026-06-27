function alias
    # alias ls → menu interactif
    if test (count $argv) -eq 1 -a "$argv[1]" = ls
        set -l choice (
            for f in ~/.config/fish/functions/*.fish
                basename $f .fish
            end | fzf \
                --prompt="alias > " \
                --preview='cat ~/.config/fish/functions/{}.fish' \
                --preview-window=right:60%
        )
        if test -n "$choice"
            $EDITOR ~/.config/fish/functions/$choice.fish
        end
        return
    end

    # alias name command → crée l'alias
    if test (count $argv) -ge 2
        set name $argv[1]
        set cmd $argv[2..]
        if command alias $name $cmd && funcsave $name
            echo "alias '$name' -> '$cmd' created"
        else
            echo "error: failed to create alias '$name'"
            return 1
        end
        return
    end

    # fallback → vrai alias
    command alias $argv
end
