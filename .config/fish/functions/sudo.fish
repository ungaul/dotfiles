function sudo --wraps=sudo -d "sudo wrapper that handles aliases"
    if functions -q -- $argv[1]
        set -l new_args (string join ' ' -- (string escape -- $argv))
        set argv fish -c "set HOME /home/gaulerie; set XDG_CONFIG_HOME /home/gaulerie/.config; set fish_function_path /home/gaulerie/.config/fish/functions \$fish_function_path; $new_args"
    end
    command sudo $argv
end
