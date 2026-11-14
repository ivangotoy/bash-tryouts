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

done_testing
