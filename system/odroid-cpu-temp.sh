#!/usr/bin/env bash
#
# Ivan Angelov ivangotoy@gmail.com
# https://digtvbg.com/
#
# Simple script to check CPU temperatures of both cpu clusters (little/big) of ODROID N2
#
TEMP0="$(awk "BEGIN {print $(cat /sys/class/thermal/thermal_zone0/temp)/1000}")"
TEMP1="$(awk "BEGIN {print $(cat /sys/class/thermal/thermal_zone1/temp)/1000}")"
printf "TEMP0 IS: ${TEMP0}C\nTEMP1 IS: ${TEMP1}C\n"
