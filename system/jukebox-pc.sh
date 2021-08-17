#!/usr/bin/env bash
#
# Ivan Angelov ivangotoy@gmail.com
# https://digtvbg.com/
#
# youtube-dl is needed :)
# 
# paplay from PulseAudio is used too.
#
# Use youtube video ID as input to download play a single audio file from Youtube on linux terminal with PulseAudio.
#

dir="/home/$USER/Downloads"
cmd="$(which youtube-dl)"
params="--geo-bypass --quiet -4 -x --audio-format wav"
baseurl="https://youtu.be/"
echo "Paste the youtube video ID hash, followed by [ENTER]:"
read video
vidurl="${baseurl}${video}"
player="$(which paplay)"
       
cd $dir             
$cmd $params $vidurl 
                         
file=$(find . -maxdepth 1 -name *$video.wav)
 
$player "$file"
