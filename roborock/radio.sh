#!/usr/bin/env bash
#
# Ivan Angelov ivangotoy@gmail.com
# https://digtvbg.com/
#
# This file resides on the Roborock vacuum cleaner in /mnt/data/muzika/ folder.
#
# It kills any instances of sox (if playing anything else at the moment)
# Shuffles radio.m3u entries and writes the result to test1.m3u
# radio.m3u is basically a list of desired online radios http streaming links one per line.
# Invoking radio.sh every time plays different station (shuffling of entries).

/root/bin/busybox killall -9 sox;

/root/bin/busybox shuf /mnt/data/muzika/radio.m3u > /mnt/data/muzika/test1.m3u;

nohup play /mnt/data/muzika/test1.m3u
