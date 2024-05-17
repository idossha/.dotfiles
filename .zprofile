
eval "$(/opt/homebrew/bin/brew shellenv)"

## Added by SimNIBS
SIMNIBS_BIN="/Users/idohaber/Applications/SimNIBS-4.0/bin"
export PATH=${PATH}:${SIMNIBS_BIN}

# FSL Setup
FSLDIR=/Users/idohaber/Applications/fsl
PATH=${FSLDIR}/share/fsl/bin:${PATH}
export FSLDIR PATH
. ${FSLDIR}/etc/fslconf/fsl.sh
