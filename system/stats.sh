#!/usr/bin/env zsh
#
# Ivan Angelov ivangotoy@gmail.com
# https://digtvbg.com/
#
# Simple script to check memory, rootfs / and cpu load.
#

export LC_ALL=C
export LANG=C

free -m | awk 'NR==2{printf "\nMemory Usage: %s/%sMB (%.2f%%)\n\n", $3,$2,$3*100/$2 }'
df -BG / | awk 'NR==2{printf "Disk Usage of / e.g. /dev/sda2 is: %d/%dGB (%s) FREE SPACE: %dGB\n\n", $3,$2,$5,$4}'
df -BM /boot 2>/dev/null | awk '$NF=="/boot"{printf "Disk Usage of /boot e.g. /dev/sda1 is: %d/%dMB (%s) FREE SPACE: %dMB\n\n", $3,$2,$5,$4}'
awk '{printf "CPU Load: %.2f\n\n", $1}' /proc/loadavg
