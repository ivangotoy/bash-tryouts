#!/usr/bin/env bash
# system/jukebox-pc.sh: works in $HOME/Downloads and plays the wav file
# yt-dlp wrote there.
. "$(dirname "$0")/lib.sh"

home="$WORK/home"
mkdir -p "$home/Downloads"
id=dQw4w9WgXcQ

# yt-dlp stub: logs its cwd and arguments, writes the file the way yt-dlp
# names it by default: "%(title)s [%(id)s].%(ext)s".
stub yt-dlp 'printf "%s\n" "$PWD" > "$LOG/yt-dlp.cwd"; printf "%s\n" "$@" > "$LOG/yt-dlp.args"
id="${@: -1}"; id="${id##*/}"; : > "Example Title [$id].wav"'
stub paplay 'printf "%s\n" "$@" > "$LOG/paplay.args"'
mkdir -p "$WORK/log"

printf '%s\n' "$id" | HOME="$home" USER=nobody-test LOG="$WORK/log" "$BASH_BIN" "$REPO/system/jukebox-pc.sh" > "$WORK/out" 2>&1
rc=$?

check 'exit status 0' test "$rc" -eq 0
check 'yt-dlp runs in $HOME/Downloads' test "$(cat "$WORK/log/yt-dlp.cwd" 2>/dev/null)" = "$home/Downloads"
check 'paplay plays the downloaded wav' test "$(cat "$WORK/log/paplay.args" 2>/dev/null)" = "./Example Title [$id].wav"

done_testing
