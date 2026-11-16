#!/usr/bin/env bash
# macgen/macgen: when shuf fails (it holds all 16.7M lines in memory) the
# run must fail instead of reporting an empty file as generated.
. "$(dirname "$0")/lib.sh"

stub shuf 'exit 1'
cd "$WORK" || exit 1
printf '00:1A:79:\n' | "$ZSH_BIN" "$REPO/macgen/macgen" > "$WORK/out" 2>&1
rc=$?
check "shuf fails: exit 1 (got $rc)" test "$rc" -eq 1
check 'shuf fails: no success message' test "$(grep -c 'GENERATED AND RANDOMIZED' "$WORK/out")" -eq 0

# split fails (e.g. a full disk while writing the parts): exit 1. zsh's
# select reads ahead on a pipe, so each answer is sent only once its
# prompt is shown.
stub shuf 'cat > /dev/null; printf "00:1a:79:00:00:01\n"'
stub split 'printf "split: write error: No space left on device\n" >&2; exit 1'
# wait_for TEXT: until TEXT is in the output (at most 30 s).
wait_for() {
	local i
	for ((i = 0; i < 300; i++)); do
		grep -q -- "$1" "$WORK/out" && return 0
		"$SLEEP_BIN" 0.1
	done
	return 1
}
: > "$WORK/out"
exec 3> >("$TIMEOUT_BIN" 60 "$ZSH_BIN" "$REPO/macgen/macgen" > "$WORK/out" 2>&1; printf '%s\n' "$?" > "$WORK/rc")
pid=$!
printf '00:1A:79:\n' >&3
wait_for '"1" for yes' && printf '1\n' >&3
wait_for 'Select 1 2 or 3' && printf '1\n' >&3
exec 3>&-
wait "$pid"
rc="$(cat "$WORK/rc" 2>/dev/null)"
check 'split fails: split was reached' grep -q 'No space left' "$WORK/out"
check "split fails: exit 1 (got $rc)" test "$rc" = 1

done_testing
