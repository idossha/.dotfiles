
## Added for freesurfer by Ido Haber on 02-21-24
export PATH=$PATH:/Users/idohaber/.my_scripts/
export FREESURFER_HOME=/Applications/freesurfer/7.4.1
export SUBJECTS_DIR=$FREESURFER_HOME/subjects
source $FREESURFER_HOME/SetUpFreeSurfer.sh

export DOCKER_HOST_IP=host.docker.internal
export DOCKER_DISPLAY=/private/tmp/com.apple.launchd.sLp1ABjeSB/org.xquartz:0
export DOCKER_HOST_IP=host.docker.internal
export DOCKER_DISPLAY=/private/tmp/com.apple.launchd.sLp1ABjeSB/org.xquartz:0
export DOCKER_HOST_IP=host.docker.internal
export DOCKER_DISPLAY=/private/tmp/com.apple.launchd.sLp1ABjeSB/org.xquartz:0

. "$HOME/.atuin/bin/env"

## Added by SimNIBS
SIMNIBS_BIN="/Users/idohaber/Applications/SimNIBS-4.5/bin"
export PATH=${PATH}:${SIMNIBS_BIN}
. "$HOME/.local/bin/env"
