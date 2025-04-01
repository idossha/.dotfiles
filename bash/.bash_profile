
## Added for freesurfer by Ido Haber on 02-21-24
export PATH=$PATH:/Users/idohaber/.my_scripts/
export FREESURFER_HOME=/Applications/freesurfer/7.4.1
export SUBJECTS_DIR=$FREESURFER_HOME/subjects
source $FREESURFER_HOME/SetUpFreeSurfer.sh


# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
__conda_setup="$('/Users/idohaber/miniconda3/bin/conda' 'shell.bash' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
else
    if [ -f "/Users/idohaber/miniconda3/etc/profile.d/conda.sh" ]; then
        . "/Users/idohaber/miniconda3/etc/profile.d/conda.sh"
    else
        export PATH="/Users/idohaber/miniconda3/bin:$PATH"
    fi
fi
unset __conda_setup
# <<< conda initialize <<<


## Added by SimNIBS
SIMNIBS_BIN="/Users/idohaber/Applications/SimNIBS-4.5/bin"
export PATH=${PATH}:${SIMNIBS_BIN}
export DOCKER_HOST_IP=host.docker.internal
export DOCKER_DISPLAY=/private/tmp/com.apple.launchd.sLp1ABjeSB/org.xquartz:0
export DOCKER_HOST_IP=host.docker.internal
export DOCKER_DISPLAY=/private/tmp/com.apple.launchd.sLp1ABjeSB/org.xquartz:0
export DOCKER_HOST_IP=host.docker.internal
export DOCKER_DISPLAY=/private/tmp/com.apple.launchd.sLp1ABjeSB/org.xquartz:0

. "$HOME/.atuin/bin/env"
