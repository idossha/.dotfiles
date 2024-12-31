

#!/usr/bin/env bash

# Bright color codes
BRIGHTRED='\033[1;31m'
BRIGHTGRN='\033[1;32m'
BRIGHTYEL='\033[1;33m'
BRIGHTBLU='\033[1;34m'
BRIGHTMAG='\033[1;35m'
BRIGHTCYN='\033[1;36m'
NC='\033[0m' # No Color

# 1) Disk usage (try Data volume first, fallback to /)
diskUsed=$(df -h /System/Volumes/Data 2>/dev/null | tail -1 | awk '{print $5}')
if [[ -z "$diskUsed" ]]; then
  diskUsed=$(df -h / | tail -1 | awk '{print $5}')
fi

# 2) CPU usage (from top -l 1)
cpuLine=$(top -l 1 | grep "CPU usage")
cpuUsage="${cpuLine#*CPU usage: }"

# 3) RAM usage (from top -l 1)
ramLine=$(top -l 1 | grep "PhysMem")
ramUsage="${ramLine#*PhysMem: }"

# 4) macOS version
macVersion=$(sw_vers -productVersion)

# 5) Network IP (assuming en0)
ip=$(ipconfig getifaddr en0 2>/dev/null)
[ -z "$ip" ] && ip="No IP found on en0"

echo -e "${BRIGHTMAG}=== System Snapshot ===${NC}"
echo -e "${BRIGHTRED}Disk:${NC} ${diskUsed} used"
echo -e "${BRIGHTGRN}CPU Usage:${NC} ${cpuUsage}"
echo -e "${BRIGHTYEL}RAM Usage:${NC} ${ramUsage}"
echo -e "${BRIGHTBLU}macOS:${NC} ${macVersion}"
echo -e "${BRIGHTCYN}network:${NC} ${ip}"
echo -e "${BRIGHTMAG}=======================${NC}"

