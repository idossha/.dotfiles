# bash configuration rc file.
# Ido Haber // ihaber@wisc.edu

# personal
export PATH="$HOME/bin:$PATH"

# docker variables
export DOCKER_HOST_IP=localhost
export DISPLAY=:0

# shell prompt
export PS1='\u|\W > '

# Set personal aliases
alias mp="cd ~/Git-Projects/"
alias md="cd ~/.dotfiles/"
alias vi='nvim'
alias t=tmux

# Atuin shell history
if [ -f "$HOME/.atuin/bin/env" ]; then
    . "$HOME/.atuin/bin/env"
fi

# Local bin path
if [ -d "$HOME/.local/bin" ]; then
    export PATH="$HOME/.local/bin:$PATH"
fi

# export XDG_CONFIG_HOME="$HOME/.config"

# Initialize tools (bash versions)
if command -v zoxide >/dev/null 2>&1; then
    eval "$(zoxide init bash)"
fi

if command -v atuin >/dev/null 2>&1; then
    eval "$(atuin init bash)"
fi

if command -v direnv >/dev/null 2>&1; then
    eval "$(direnv hook bash)"
fi

# VI mode for terminal
set -o vi

PROMPT='%n@%m|%1~$(git rev-parse --git-dir > /dev/null 2>&1 && echo " ($(git branch --show-current 2>/dev/null))") > '


