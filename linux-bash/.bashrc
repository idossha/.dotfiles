# bash configuration rc file.
# Ido Haber // ihaber@wisc.edu

# personal
export PATH="$HOME/bin:$PATH"

# docker variables
export DOCKER_HOST_IP=localhost
export DISPLAY=:0

# Set personal aliases
alias mp="cd ~/Git-Projects/"
alias md="cd ~/.dotfiles/"
alias vi='nvim'
alias t=tmux

# Local bin path
if [ -d "$HOME/.local/bin" ]; then
    export PATH="$HOME/.local/bin:$PATH"
fi

# export XDG_CONFIG_HOME="$HOME/.config"

# Initialize tools (bash versions)
# zoxide init (if installed)
if command -v zoxide >/dev/null 2>&1; then
    eval "$(zoxide init bash)"
fi

# direnv hook (if installed)
if command -v direnv >/dev/null 2>&1; then
    eval "$(direnv hook bash)"
fi

# Atuin shell history (after other hooks)
if command -v atuin >/dev/null 2>&1; then
    eval "$(atuin init bash)"
fi

# VI mode for terminal
set -o vi

export PS1='\u@\h|\W$(git branch --show-current 2>/dev/null | sed "s/^/ (/;s/$/)/") > '
