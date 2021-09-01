#!/usr/bin/env zsh
#
# Ivan Angelov ivangotoy@gmail.com
# https://digtvbg.com/
#
# Simple script to check memory, rootfs / and cpu load.
#

free -m | awk 'NR==2{printf "\nMemory Usage: %s/%sMB (%.2f%%)\n\n", $3,$2,$3*100/$2 }'
df -h | awk '$NF=="/"{printf "Disk Usage of / e.g. /dev/sda2 is: %d/%dGB (%s) FREE SPACE: %dGB\n\n", $3,$2,$5,$4}'
df -h | awk '$NF=="/boot"{printf "Disk Usage of /boot e.g. /dev/sda1 is: %d/%dMB (%s) FREE SPACE: %dMB\n\n", $3,$2,$5,$4}'
top -bn1 | grep load | awk '{printf "CPU Load: %.2f\n\n", $(NF-2)}'
