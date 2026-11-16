#!/usr/bin/env bash
# tests/run.sh: a run without any test file is not a pass; a passing and a
# failing test file give exit status 0 and 1. Runs a copy of run.sh in a
# scratch tree (not in place: it would run this test again).
. "$(dirname "$0")/lib.sh"

tree="$WORK/tree"
mkdir -p "$tree/tests"
cp "$REPO/tests/run.sh" "$tree/tests/run.sh"

run_runner() { "$BASH_BIN" "$tree/tests/run.sh" > "$WORK/out" 2>&1; }

run_runner
rc=$?
check "no test files: exit 1 (got $rc)" test "$rc" -eq 1

printf 'exit 0\n' > "$tree/tests/test-pass.sh"
run_runner
rc=$?
check "one passing test file: exit 0 (got $rc)" test "$rc" -eq 0

printf 'exit 1\n' > "$tree/tests/test-fail.sh"
run_runner
rc=$?
check "one failing test file: exit 1 (got $rc)" test "$rc" -eq 1

done_testing
