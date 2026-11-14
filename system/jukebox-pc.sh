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
params=(--quiet -4 -x --audio-format wav)

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
# yt-dlp prints the final path (after the conversion to wav and the move),
# so any output template in the user's yt-dlp config works.
file="$(yt-dlp "${params[@]}" --print after_move:filepath "${baseurl}${video}")" || exit 1
if [[ -z "$file" || ! -f "$file" ]]; then
	printf 'Downloaded wav file for %s not found in %s (yt-dlp reported "%s")\n' "$video" "$dir" "$file"
	exit 1
fi

paplay "$file"
