#!/usr/bin/env bash
# shellcheck disable=SC2034  # the *_BIN paths are used by the sourcing tests
#
# Sourced by tests/test-*.sh. Every test runs the scripts against stub
# binaries: PATH holds only a stub directory and a directory of symlinks to
# local, side-effect-free tools (coreutils, shells, grep, sed, awk, jq, ...),
# so a missing stub fails with "command not found" instead of reaching a
# real curl, ssh, ipset or systemctl.
#
# REPO is the tree under test (default: this checkout), so a test can be run
# against another checkout: REPO=/path/to/tree tests/test-foo.sh

REPO="${REPO:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"

scratch="${TMPDIR:-${XDG_CACHE_HOME:-$HOME/.cache}}"
mkdir -p "$scratch" || exit 1
WORK="$(mktemp -d "$scratch/bash-tryouts-test.XXXXXX")" || exit 1
trap 'rm -rf "$WORK"' EXIT

STUBS="$WORK/stubs"
SAFE="$WORK/safe"
mkdir -p "$STUBS" "$SAFE"

BASH_BIN="$(command -v bash)"
ZSH_BIN="$(command -v zsh)"
TIMEOUT_BIN="$(command -v timeout)"
SLEEP_BIN="$(command -v sleep)"
UNSHARE_BIN="$(command -v unshare)"

for tool in awk basename bash cat chmod cmp column cp cut date dirname env find \
	grep gzip head id jq ln ls mkdir mktemp mv printf readlink rg rm rmdir sed sh \
	sort stat tail tar tee touch tr uniq wc zsh; do
	path="$(command -v "$tool")" && ln -s "$path" "$SAFE/$tool"
done
unset tool path

PATH="$STUBS:$SAFE"
export PATH

failures=0

# stub NAME BODY: a stub command NAME whose body is bash code.
stub() {
	printf '#!%s\n%s\n' "$BASH_BIN" "$2" > "$STUBS/$1"
	chmod +x "$STUBS/$1"
}

# patched SCRIPT SED-EXPR...: a copy of $REPO/SCRIPT in $WORK with only its
# hard coded paths rewritten (each SED-EXPR is a sed s command); prints the
# copy's path. Fails when an expression changed nothing.
patched() {
	local src="$REPO/$1" dst
	dst="$WORK/$(basename "$1")"
	cp "$src" "$dst"
	shift
	local expr
	for expr in "$@"; do
		sed -i -e "$expr" "$dst"
	done
	if [[ "$(cat "$src")" == "$(cat "$dst")" ]]; then
		printf 'patched: no change in %s\n' "$src" >&2
		return 1
	fi
	printf '%s\n' "$dst"
}

ok() { printf '  ok   %s\n' "$1"; }
not_ok() { printf '  FAIL %s\n' "$1"; failures=$((failures + 1)); }

# check DESCRIPTION COMMAND...: ok when COMMAND succeeds.
check() {
	local what="$1"
	shift
	if "$@"; then ok "$what"; else not_ok "$what"; fi
}

# skip REASON: the test cannot run here (exit 77, reported as SKIP).
skip() {
	printf '  SKIP %s\n' "$1"
	exit 77
}

# need_userns: skip unless an unprivileged user namespace gives uid 0, the
# way the root-only scripts are run (EUID 0, no real privileges).
need_userns() {
	[[ -n "$UNSHARE_BIN" ]] && [[ "$("$UNSHARE_BIN" -r id -u 2>/dev/null)" == 0 ]] ||
		skip 'no unprivileged user namespace (unshare -r) on this host'
}

done_testing() {
	exit "$(( failures > 0 ))"
}
