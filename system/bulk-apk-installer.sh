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
#   *.apk and *.APK files in that directory and its subdirectories are installed.

if ! command -v adb &>/dev/null; then
	printf 'No ADB (get it from google platform tools) available in the system, please, act accordingly. Now we abort that mission.\n'
	exit 1
fi

apks=(./**/*.(apk|APK)(N.))

if (( ${#apks} == 0 )); then
	printf 'No apk files found in %s\n' "$PWD"
	exit 1
fi

failed=0
for apk in $apks; do
	printf 'Installing %s\n' "$apk"
	adb install "$apk" || failed=$((failed + 1))
done

if (( failed )); then
	printf '%d of %d apk files failed to install.\n' "$failed" "${#apks}"
	exit 1
fi
