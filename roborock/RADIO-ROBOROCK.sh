#!/usr/bin/env zsh
#
# Ivan Angelov ivangotoy@gmail.com
# https://digtvbg.com/
# What this 1 line does is:
# - ssh connection to our roborock device
# - invoking our online radio script on the device 
# - makes sure if we terminate our session locally , roborock will still continue to produce some sounds.

ssh robo 'nohup /mnt/data/muzika/radio.sh > foo.out 2> foo.err < /dev/null &'
