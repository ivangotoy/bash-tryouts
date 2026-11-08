#!/usr/bin/env zsh
#
# Ivan Angelov ivangotoy@gmail.com
# https://digtvbg.com/
#
# What this 1 line does is:
# - ssh connection to our rooted Roborock device
# - execute our music script 
# - makes sure if we stop our local session or close window the remote device will keep playing.

ssh robo 'nohup /mnt/data/muzika/muzika.sh > foo.out 2> foo.err < /dev/null &'
