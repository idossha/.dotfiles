# Added for freesurfer by Ido Haber
export PATH=$PATH:$HOME/.my_scripts/
# export FREESURFER_HOME=/usr/local/freesurfer  # Uncomment and set correct path for Linux
# export SUBJECTS_DIR=$FREESURFER_HOME/subjects
# source $FREESURFER_HOME/SetUpFreeSurfer.sh

# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
__conda_setup="$('$HOME/miniconda3/bin/conda' 'shell.bash' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
else
    if [ -f "$HOME/miniconda3/etc/profile.d/conda.sh" ]; then
        . "$HOME/miniconda3/etc/profile.d/conda.sh"
    else
        export PATH="$HOME/miniconda3/bin:$PATH"
    fi
fi
unset __conda_setup
# <<< conda initialize <<<

# Docker configuration for Linux
export DOCKER_HOST_IP=localhost
# export DISPLAY=:0  # Uncomment if using X11

# Atuin shell history
if [ -f "$HOME/.atuin/bin/env" ]; then
    . "$HOME/.atuin/bin/env"
fi

# Local bin path
if [ -d "$HOME/.local/bin" ]; then
    export PATH="$HOME/.local/bin:$PATH"
fi

# SimNIBS (if installed)
# SIMNIBS_BIN="$HOME/Applications/SimNIBS/bin"
# export PATH=${PATH}:${SIMNIBS_BIN}
