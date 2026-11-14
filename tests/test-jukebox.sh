#!/usr/bin/env bash
# system/jukebox-pc.sh: works in $HOME/Downloads and plays the file whose
# path yt-dlp reports (--print after_move:filepath), whatever its name; a
# missing report or file is a clear error.
. "$(dirname "$0")/lib.sh"

home="$WORK/home"
mkdir -p "$home/Downloads" "$WORK/log"
id=dQw4w9WgXcQ

# yt-dlp stub: logs cwd and arguments, writes the wav under NAME (default:
# yt-dlp's "%(title)s [%(id)s].%(ext)s"), prints the final path for
# --print after_move:filepath unless PRINT=none; PRINT=missing reports a
# path that does not exist.
stub yt-dlp 'printf "%s\n" "$PWD" > "$LOG/yt-dlp.cwd"; printf "%s\n" "$@" > "$LOG/yt-dlp.args"
id="${@: -1}"; id="${id##*/}"; name="${NAME:-Example Title [$id].wav}"
: > "$name"
want=; prev=
for a; do [[ "$prev" == --print && "$a" == after_move:filepath ]] && want=1; prev="$a"; done
[[ -z "$want" || "$PRINT" == none ]] && exit 0
[[ "$PRINT" == missing ]] && { printf "%s\n" "$PWD/gone.wav"; exit 0; }
printf "%s\n" "$PWD/$name"'
stub paplay 'printf "%s\n" "$@" > "$LOG/paplay.args"'

run_jukebox() {
	rm -f "$WORK/log/paplay.args"
	printf '%s\n' "$id" | env HOME="$home" USER=nobody-test LOG="$WORK/log" "$@" "$BASH_BIN" "$REPO/system/jukebox-pc.sh" > "$WORK/out" 2>&1
}

run_jukebox
rc=$?
check "default name: exit 0 (got $rc)" test "$rc" -eq 0
check 'yt-dlp runs in $HOME/Downloads' test "$(cat "$WORK/log/yt-dlp.cwd" 2>/dev/null)" = "$home/Downloads"
check 'default name: paplay plays the reported wav' test "$(cat "$WORK/log/paplay.args" 2>/dev/null)" = "$home/Downloads/Example Title [$id].wav"

# A yt-dlp config with its own -o template: the name has no video ID.
run_jukebox NAME='Example Title.wav'
rc=$?
check "own output template: exit 0 (got $rc)" test "$rc" -eq 0
check 'own output template: paplay plays the reported wav' test "$(cat "$WORK/log/paplay.args" 2>/dev/null)" = "$home/Downloads/Example Title.wav"

run_jukebox PRINT=none
rc=$?
check "no path reported: exit 1 (got $rc)" test "$rc" -eq 1
check 'no path reported: nothing played' test ! -e "$WORK/log/paplay.args"
check 'no path reported: error message' grep -q 'not found' "$WORK/out"

run_jukebox PRINT=missing
rc=$?
check "reported file missing: exit 1 (got $rc)" test "$rc" -eq 1
check 'reported file missing: nothing played' test ! -e "$WORK/log/paplay.args"

done_testing
