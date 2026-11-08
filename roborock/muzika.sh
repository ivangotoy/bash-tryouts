#!/usr/bin/env bash
#
# Ivan Angelov ivangotoy@gmail.com
# https://digtvbg.com/
#
# This file resides on the Roborock vacuum cleaner in /mnt/data/muzika/ folder.
#
# It makes sure sox is not running before shuffling a "newly ordered" playlist.
# Then it simply plays the shuffled result.
# > redirection ensures sane results on each and every invocation.
# playlist.m3u consists of local mp3 files list in the same folder.

dir=/mnt/data/muzika

/root/bin/busybox killall -9 sox 2>/dev/null

/root/bin/busybox shuf "$dir/playlist.m3u" > "$dir/test.m3u"

nohup play "$dir/test.m3u"
