#!/usr/bin/env zsh
#
# Ivan Angelov ivangotoy@gmail.com
# https://digtvbg.com/
# 
# Stops any audio playing on the Roborock: kills every sox process there
# over ssh (host alias "robo").
#
ssh robo '/root/bin/busybox killall -9 sox'
