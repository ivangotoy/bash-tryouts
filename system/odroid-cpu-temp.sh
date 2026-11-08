#!/usr/bin/env bash
#
# Ivan Angelov ivangotoy@gmail.com
# https://digtvbg.com/
#
# Simple script to check CPU temperatures of both cpu clusters (little/big) of ODROID N2
#
TEMP0="$(awk '{print $1/1000}' /sys/class/thermal/thermal_zone0/temp)" || exit 1
TEMP1="$(awk '{print $1/1000}' /sys/class/thermal/thermal_zone1/temp)" || exit 1
printf 'TEMP0 IS: %sC\nTEMP1 IS: %sC\n' "$TEMP0" "$TEMP1"
