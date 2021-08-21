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

if [[ -z "$(adb version)" ]]; then
	printf "No ADB (get it from google platform tools) available in the system, please, act accordingly. Now we abort that mission.\n"
    exit 1
fi

for APK in $(find . -type f -name "*.APK" -o -name "*.apk" -printf '%f\n')
do
adb install "$APK"
wait
done
