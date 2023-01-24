

export NIXPKGS_ALLOW_UNFREE=1
# export PATH="/Users/ctafur/.nix-profile/bin:$PATH"
export PATH="$PATH:/Users/ctafur/.local/bin"
export EDITOR="nvim"


# bindkey -v
# bindkey '^R' history-incremental-search-backward


alias ls="ls -G"
alias v="alacritty -e nvim $PWD"


# alias nerdctl="lima nerdctl"

eval "$(starship init bash)"
# autoload -Uz compinit && compinit




