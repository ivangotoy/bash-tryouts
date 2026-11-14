#!/usr/bin/env bash
# tools/lint.sh: a shellcheck that fails (exit status != 0) must fail the
# lint run even when it printed nothing on stdout, e.g. a broken SHELLCHECK;
# a run that could not check the requested files must fail too.
. "$(dirname "$0")/lib.sh"

printf '#!/usr/bin/env bash\nprintf "hi\\n"\n' > "$WORK/clean.sh"

stub shellcheck-clean 'exit 0'
stub shellcheck-findings 'printf "%s:2:1: warning: x [SC0000]\n" "${@: -1}"; exit 1'
stub shellcheck-broken 'printf "shellcheck: cannot run\n" >&2; exit 2'

run_lint() {
	SHELLCHECK="$STUBS/$1" "$BASH_BIN" "$REPO/tools/lint.sh" "$WORK/clean.sh" > "$WORK/out" 2>&1
}

run_lint shellcheck-clean
check 'clean file passes' test $? -eq 0
run_lint shellcheck-findings
check 'shellcheck findings fail the run' test $? -eq 1
run_lint shellcheck-broken
check 'shellcheck exit status 2 without output fails the run' test $? -eq 1

# Nothing checked is not a pass: a missing file argument, or no file list
# because git ls-files failed (not a checkout).
SHELLCHECK="$STUBS/shellcheck-clean" "$BASH_BIN" "$REPO/tools/lint.sh" "$WORK/no-such-file.sh" > "$WORK/out" 2>&1
check 'missing file argument fails the run' test $? -eq 1

stub git 'printf "fatal: not a git repository\n" >&2; exit 128'
SHELLCHECK="$STUBS/shellcheck-clean" "$BASH_BIN" "$REPO/tools/lint.sh" > "$WORK/out" 2>&1
check 'git ls-files failing fails the run' test $? -eq 1

done_testing
