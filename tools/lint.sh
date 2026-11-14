#!/usr/bin/env bash
#
# Syntax check every script in the repository (or only the files given as
# arguments) with the shell named in its shebang, and run shellcheck on the
# bash/sh/ash ones when shellcheck is installed (shellcheck has no zsh
# support). Files without a shell shebang are skipped.
#
#   tools/lint.sh                 all tracked files
#   tools/lint.sh cron/*.sh       only these files
#   SHELLCHECK=/path/to/shellcheck tools/lint.sh
#
# Exit status: 0 when every check passed, 1 otherwise.

cd "$(dirname "$0")/.." || exit 1

shellcheck="${SHELLCHECK:-$(command -v shellcheck)}"
if [[ -z "$shellcheck" ]]; then
	printf 'shellcheck not found, only syntax checks are run.\n' >&2
fi

# busybox ash scripts: use busybox when it is there, else bash in POSIX mode.
if command -v busybox >/dev/null 2>&1; then
	ash_check=(busybox ash -n)
else
	ash_check=(bash --posix -n)
fi

if (( $# )); then
	files=("$@")
elif list="$(git ls-files)"; then
	mapfile -t files <<< "$list"
else
	printf 'git ls-files failed: run this in a checkout or name the files to check.\n' >&2
	exit 1
fi

failed=0
checked=0
for f in "${files[@]}"; do
	if [[ ! -f "$f" ]]; then
		# A named file that is not there is an error; a tracked file
		# deleted in the work tree is just skipped.
		if (( $# )); then
			printf '%s: not a file\n' "$f" >&2
			failed=1
		fi
		continue
	fi
	IFS= read -r first < "$f" || true
	case $first in
		'#!'*zsh*) shell='zsh'; syntax=(zsh -n) ;;
		'#!'*bash*) shell='bash'; syntax=(bash -n) ;;
		'#!'*ash*) shell='busybox'; syntax=("${ash_check[@]}") ;;
		'#!'*/sh|'#!'*/sh' '*|'#!'*' sh'|'#!'*' sh '*) shell='sh'; syntax=(sh -n) ;;
		*) continue ;;
	esac
	checked=$((checked + 1))

	if "${syntax[@]}" "$f"; then
		syn=ok
	else
		syn=FAIL
		failed=1
	fi

	sc=-
	if [[ "$shell" != zsh && -n "$shellcheck" ]]; then
		# One run per file; its exit status counts too, so a shellcheck
		# that cannot run (status 2+, nothing on stdout) is a failure.
		out="$("$shellcheck" -s "$shell" -f gcc "$f")"
		rc=$?
		sc=0
		if [[ -n "$out" ]]; then
			printf '%s\n' "$out"
			sc=$(wc -l <<< "$out")
		fi
		if (( rc != 0 || sc > 0 )); then
			(( sc > 0 )) || sc="error($rc)"
			failed=1
		fi
	fi

	printf '%-45s %-8s syntax=%-4s shellcheck=%s\n' "$f" "$shell" "$syn" "$sc"
done

printf '%d files checked, %s\n' "$checked" "$([[ $failed -eq 0 ]] && echo 'all passed' || echo 'FAILURES above')"
exit "$failed"
