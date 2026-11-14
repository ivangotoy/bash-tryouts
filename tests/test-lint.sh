#!/usr/bin/env bash
# tools/lint.sh: a shellcheck that fails (exit status != 0) must fail the
# lint run even when it printed nothing on stdout, e.g. a broken SHELLCHECK.
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

done_testing
