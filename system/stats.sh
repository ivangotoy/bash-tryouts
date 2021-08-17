#!/usr/bin/env zsh
#
# Ivan Angelov ivangotoy@gmail.com
# https://digtvbg.com/
#
# Simple script to check memory, disk 1 and 2, cpu load.
#

free -m | awk 'NR==2{printf "Memory Usage: %s/%sMB (%.2f%%)\n", $3,$2,$3*100/$2 }'
df -h | awk '$NF=="/"{printf "Disk Usage of / e.g. /dev/sda2 is: %d/%dGB (%s) FREE SPACE: %dGB\n", $3,$2,$5,$4}'
df -h | awk '$NF=="/boot"{printf "Disk Usage of /boot e.g. /dev/sda1 is: %d/%dMB (%s) FREE SPACE: %dMB\n", $3,$2,$5,$4}'
top -bn1 | grep load | awk '{printf "CPU Load: %.2f\n", $(NF-2)}'
