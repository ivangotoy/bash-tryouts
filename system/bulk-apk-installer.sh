#!/usr/bin/env zsh
#
# Ivan Angelov ivangotoy@gmail.com
# https://digtvbg.com/
#
# adb connection to phone is properly set up e.g. adb shell / pull / push works.
#
# How to use this script:
# 
# - put several apk files that you need install in one folder on your linux machine
#
# - connect the phone to pc with working adb connection
#
# - execute the script from the directory with apk files.

for APK in *.apk
do
adb install "$APK"
wait
done
exit 0
