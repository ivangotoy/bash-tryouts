#!/usr/bin/env bash
#
# Runs every tests/test-*.sh (or only the files given as arguments) and
# prints one PASS/FAIL/SKIP line per file (SKIP: exit status 77). The tests
# use stub binaries only, see tests/lib.sh. Exit status: 0 when no test file
# failed (skips are not failures), 1 otherwise or when there was none.
#
#   tests/run.sh
#   tests/run.sh tests/test-lint.sh
#   REPO=/path/to/other/tree tests/run.sh     test another checkout

cd "$(dirname "$0")/.." || exit 1

if (( $# )); then
	files=("$@")
else
	files=(tests/test-*.sh)
	[[ -e "${files[0]}" ]] || files=()
fi

failed=0
skipped=0
for t in "${files[@]}"; do
	printf '%s\n' "$t"
	bash "$t"
	case $? in
		0) printf 'PASS %s\n' "$t" ;;
		77) printf 'SKIP %s\n' "$t"; skipped=$((skipped + 1)) ;;
		*) printf 'FAIL %s\n' "$t"; failed=$((failed + 1)) ;;
	esac
done

printf '%d test files, %d failed, %d skipped\n' "${#files[@]}" "$failed" "$skipped"
# No test file at all is not a pass.
if (( ${#files[@]} == 0 )); then
	printf 'No tests/test-*.sh found, nothing was tested.\n' >&2
	exit 1
fi
(( failed == 0 ))
