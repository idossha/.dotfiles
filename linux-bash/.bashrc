# bash configuration rc file.
# Ido Haber // ihaber@wisc.edu
# December 30, 2024

# personal
export PATH="$HOME/bin:$PATH"
export PATH=$PATH:/usr/local/go/bin
export PATH=$PATH:$HOME/.my_scripts/

# neuro programs (Linux versions)
# export FREESURFER_HOME=/usr/local/freesurfer
# export SUBJECTS_DIR=$HOME/subjects
# source $FREESURFER_HOME/SetUpFreeSurfer.sh >/dev/null 2>&1  # print output suppressed
# export PATH="/usr/local/mrtrix3/bin:$PATH"

# matlab (Linux version - adjust paths as needed)
# export LD_LIBRARY_PATH=/usr/local/MATLAB/MATLAB_Runtime/R2024a/runtime/glnxa64:/usr/local/MATLAB/MATLAB_Runtime/R2024a/bin/glnxa64:/usr/local/MATLAB/MATLAB_Runtime/R2024a/sys/os/glnxa64:$LD_LIBRARY_PATH

# docker variables
export DOCKER_HOST_IP=localhost
export DISPLAY=:0

# automatic prompt for new terminals
# ~/terminal_info.sh

# shell prompt
export PS1='\u|\W > '

# command auto-correction (bash doesn't have built-in correction like zsh)
# shopt -s cdspell  # Enable minor spell corrections for cd

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
