#!/usr/bin/env bash
#
# Ivan Angelov ivangotoy@gmail.com
# https://digtvbg.com/
#
# yt-dlp is needed :)
#
# paplay from PulseAudio is used too.
#
# Use a youtube video ID as input to download and play a single audio file
# from Youtube on the linux terminal with PulseAudio.
# The wav file is kept in ~/Downloads.

dir="$HOME/Downloads"
baseurl="https://youtu.be/"
params=(--geo-bypass --quiet -4 -x --audio-format wav)

for tool in yt-dlp paplay; do
	if ! command -v "$tool" >/dev/null 2>&1; then
		printf '%s not found, please install it.\n' "$tool"
		exit 1
	fi
done

echo "Paste the youtube video ID hash, followed by [ENTER]:"
read -r video
if [[ ! "$video" =~ ^[A-Za-z0-9_-]+$ ]]; then
	printf 'That does not look like a youtube video ID.\n'
	exit 1
fi

cd "$dir" || exit 1
yt-dlp "${params[@]}" "${baseurl}${video}" || exit 1

# yt-dlp names the file "%(title)s [%(id)s].%(ext)s" by default.
file=$(find . -maxdepth 1 -name "*\[${video}\].wav" -print -quit)
if [[ -z "$file" ]]; then
	printf 'Downloaded wav file for %s not found in %s\n' "$video" "$dir"
	exit 1
fi

paplay "$file"
