export CONFIG_DIR=$HOME/.config/
export SKETCHY_DIR=$CONFIG_DIR/sketchybar/
export FREESURFER_HOME=/Applications/freesurfer/7.4.1
export SUBJECTS_DIR=$HOME/Desktop/subjects
source $FREESURFER_HOME/SetUpFreeSurfer.sh >/dev/null 2>&1  #print output is surpressed.
export PATH=$PATH:/usr/local/go/bin
export PATH=$PATH:/Users/idohaber/.my_scripts/
export ZSH="$HOME/oh-my-zsh"
export PATH="/Users/idohaber/Applications/mrtrix3/bin:$PATH"
export PATH="$(brew --prefix qt@5)/bin:$PATH"
export DYLD_LIBRARY_PATH=/Applications/MATLAB/MATLAB_Runtime/R2024a/runtime/maca64:/Applications/MATLAB/MATLAB_Runtime/R2024a/bin/maca64:/Applications/MATLAB/MATLAB_Runtime/R2024a/sys/osmaca64:/Applications/MATLAB/MATLAB_Runtime/R2024a/extern/bin/maca64:$DYLD_LIBRARY_PATH

~/terminal_info.sh #automatic prompt for new terminals

# shell prompt
export PS1='%n|%1~ > '

# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:/usr/local/bin:$PATH

# command auto-correction.
ENABLE_CORRECTION="true"

# display red dots whilst waiting for completion.
COMPLETION_WAITING_DOTS="true"

# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Add wisely, as too many plugins slow down shell startup.
plugins=(git zsh-autosuggestions zsh-syntax-highlighting web-search aliases)
   
source $ZSH/oh-my-zsh.sh

# Set up fzf key bindings and fuzzy completion
source <(fzf --zsh)

HISTFILE=~/.bash_history
HISTSIZE=1000
SAVEHIST=1000
HISTFILESIZE=2000

# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR='vim'
# else
#   export EDITOR='nvim'
# fi


# Set personal aliases, overriding those provided by oh-my-zsh libs,
# plugins, and themes. Aliases can be placed here, though oh-my-zsh
# users are encouraged to define aliases within the ZSH_CUSTOM folder.
# For a full list of active aliases, run `alias`.

alias zshconfig="mate ~/.zshrc"
alias mp="cd ~/Desktop/Git-Projects/"
alias ms="cd ~/Applications/SimNIBS-4.1/"
alias md="cd ~/.dotfiles/"
alias mdarp="cd ~/Desktop/Git-Projects/TI-2024"
alias mshana='process_mesh_files.sh /Users/idohaber/Desktop/.Mesh_Analyze/'
alias mshana2='process_mesh_files_new.sh /Users/idohaber/Desktop/.Mesh_Analyze/'
alias matme='/Applications/MATLAB_R2024a.app/bin/matlab  -nodisplay -nosplash'



# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
__conda_setup="$('/opt/miniconda3/bin/conda' 'shell.zsh' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
else
    if [ -f "/opt/miniconda3/etc/profile.d/conda.sh" ]; then
        . "/opt/miniconda3/etc/profile.d/conda.sh"
    else
        export PATH="/opt/miniconda3/bin:$PATH"
    fi
fi
unset __conda_setup
# <<< conda initialize <<<

export PATH=`brew --prefix`/opt/qt5/bin:$PATH
export DOCKER_HOST_IP=host.docker.internal
export DISPLAY=host.docker.internal:0
export DOCKER_HOST_IP=host.docker.internal
export DISPLAY=host.docker.internal:0
