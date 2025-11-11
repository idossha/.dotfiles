# Added for freesurfer by Ido Haber
export PATH=$PATH:$HOME/.my_scripts/
# export FREESURFER_HOME=/usr/local/freesurfer  # Uncomment and set correct path for Linux
# export SUBJECTS_DIR=$FREESURFER_HOME/subjects
# source $FREESURFER_HOME/SetUpFreeSurfer.sh

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
