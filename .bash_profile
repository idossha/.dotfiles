
## Added for freesurfer by Ido Haber on 02-21-24

export FREESURFER_HOME=/Applications/freesurfer/7.4.1
export SUBJECTS_DIR=$FREESURFER_HOME/subjects
source $FREESURFER_HOME/SetUpFreeSurfer.sh



## Added by SimNIBS
SIMNIBS_BIN="/Users/idohaber/Applications/SimNIBS-4.0/bin"
export PATH=${PATH}:${SIMNIBS_BIN}


# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
__conda_setup="$('/Users/idohaber/opt/anaconda3/bin/conda' 'shell.bash' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
else
    if [ -f "/Users/idohaber/opt/anaconda3/etc/profile.d/conda.sh" ]; then
        . "/Users/idohaber/opt/anaconda3/etc/profile.d/conda.sh"
    else
        export PATH="/Users/idohaber/opt/anaconda3/bin:$PATH"
    fi
fi
unset __conda_setup
# <<< conda initialize <<<


