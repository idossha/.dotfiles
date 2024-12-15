
#!/bin/zsh

# ANSI color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo  "${BLUE}========================================${NC}"
echo  "${GREEN}        Welcome, $(whoami)!${NC}"
echo  "${BLUE}========================================${NC}"

# Display current date and time
echo  "${YELLOW}🕒 Date & Time:${NC} $(date)"

# Display CPU usage
CPU_USAGE=$(top -l 1 | grep "CPU usage" | awk '{print $3+$5"%"}')
echo  "${YELLOW}🖥️  CPU Usage:${NC} ${CPU_USAGE}"

# Display Disk usage
DISK_USED=$(df -h / | tail -1 | awk '{print $5}')
DISK_TOTAL=$(df -h / | tail -1 | awk '{print $2}')
echo  "${YELLOW}💾 Disk Usage:${NC} ${DISK_USED} used of ${DISK_TOTAL}"

# Display Battery status (if applicable)
if [[ "$(pmset -g batt)" == *"InternalBattery"* ]]; then
    BATTERY=$(pmset -g batt | grep -Eo "\d+%")
    echo  "${YELLOW}🔋 Battery:${NC} ${BATTERY}"
fi

echo  "${BLUE}========================================${NC}"

