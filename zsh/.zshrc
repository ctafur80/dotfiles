





# export TERM="xterm-256color"



export XDC_CONFIG_HOME="${HOME}/.config"


export NIXPKGS_ALLOW_UNFREE=1
# export PATH="$PATH:/Users/ctafur/.local/bin"
export EDITOR="nvim"

# export PATH="/nix/var/nix/profiles/default/bin:$PATH"
export PATH="${HOME}/Documents/scripts:$PATH"


bindkey -e # Emacs key bindings
# bindkey '^R' history-incremental-search-backward
# bindkey "^P" up-line-or-search
# bindkey "^N" down-line-or-search


alias ls="ls -G"
# alias nvim="tmux ; nvim"
alias tectonic="tectonic -X" # the new Tectonic interface with subcommands


# TODO Terminar de hacerlo
stty -ixon




# export LUA_PATH="${HOME}/Documents/scripts/backups-lua/lua_modules/lib/luarocks"
# export LUA_CPATH="${HOME}/Documents/scripts/backups-lua/lua_modules/lib/luarocks"

# alias v="alacritty -e nvim $PWD"


# alias nerdctl="lima nerdctl"


eval "$(pandoc --bash-completion)"

eval "$(starship init zsh)"
autoload -Uz compinit && compinit

# Removes duplicates in PATH
# case ":$PATH:" in
#     *":$new_entry:"*) :;; # already there
#     *) PATH="$new_entry:$PATH";; # or PATH="$PATH:$new_entry"
# esac


# # Nix
# if [ -e '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh' ]; then
#   . '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh'
# fi
# # End Nix






