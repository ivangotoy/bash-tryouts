#!/usr/bin/env bash
#
# Ivan Angelov ivangotoy@gmail.com
# https://digtvbg.com/
#
# This file resides on the Roborock vacuum cleaner in /mnt/data/muzika/ folder.
#
# It makes sure sox is not running before shulling a "newly oderdered" playlist.
# Then it simply plays the shuffled result. 
# > redirection ensures sane results on each and every invocation.
# playlist.m3u consists of local mp3 files list in the same folder.

/root/bin/busybox killall -9 sox;

/root/bin/busybox shuf /mnt/data/muzika/playlist.m3u > /mnt/data/muzika/test.m3u;

nohup play /mnt/data/muzika/test.m3u
