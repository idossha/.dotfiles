# zsh configuration rc file. 
# Ido Haber // ihaber@wisc.edu
# December 30, 2024

# personal
export PATH="$HOME/bin:$PATH"
export PATH=$PATH:/usr/local/go/bin
export PATH=$PATH:/Users/idohaber/.my_scripts/
export SKETCHY_DIR=$CONFIG_DIR/sketchybar/

# neuro programs 
export FREESURFER_HOME=/Applications/freesurfer/7.4.1
export SUBJECTS_DIR=$HOME/Desktop/subjects
source $FREESURFER_HOME/SetUpFreeSurfer.sh >/dev/null 2>&1  #print output is surpressed.
export PATH="/Users/idohaber/Applications/mrtrix3/bin:$PATH"

# matlab
export DYLD_LIBRARY_PATH=/Applications/MATLAB/MATLAB_Runtime/R2024a/runtime/maca64:/Applications/MATLAB/MATLAB_Runtime/R2024a/bin/maca64:/Applications/MATLAB/MATLAB_Runtime/R2024a/sys/osmaca64:/Applications/MATLAB/MATLAB_Runtime/R2024a/extern/bin/maca64:$DYLD_LIBRARY_PATH

# docker variables
export PATH=`brew --prefix`/opt/qt5/bin:$PATH
export DOCKER_HOST_IP=host.docker.internal
export DISPLAY=host.docker.internal:0

# automatic prompt for new terminals
# ~/terminal_info.sh 

# shell prompt
export PS1='%n|%1~ > '

# command auto-correction.
ENABLE_CORRECTION="true"

# display red dots whilst waiting for completion.
COMPLETION_WAITING_DOTS="true"

# oh-my-zsh stuff:
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Add wisely, as too many plugins slow down shell startup.

export ZSH="$HOME/oh-my-zsh"
# oh-my-zsh theme (if you have one), plugin definitions, etc.
plugins=(git zsh-autosuggestions zsh-syntax-highlighting web-search aliases)
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=#d79921'
source $ZSH/oh-my-zsh.sh  # Now source oh-my-zsh

# Set personal aliases, overriding those provided by oh-my-zsh libs,
# For a full list of active aliases, run `alias`.

alias zshconfig="mate ~/.zshrc"
alias mp="cd ~/Git-Projects/"
alias ms="cd ~/Applications/SimNIBS-4.5/"
alias md="cd ~/.dotfiles/"
alias mo="cd ~/Silicon_Mind/"
alias matme='/Applications/MATLAB_R2024a.app/bin/matlab  -nodisplay -nosplash'
alias vi='nvim'
alias t=tmux


. "$HOME/.atuin/bin/env"

# export XDG_CONFIG_HOME="/Users/idohaber/.config"

eval "$(zoxide init zsh)"
eval "$(atuin init zsh)"
eval "$(direnv hook zsh)"

# VI mode for terminal 
bindkey -v

