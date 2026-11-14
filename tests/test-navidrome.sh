#!/usr/bin/env bash
# cron/navidrome-update-openwrt-ash, run with bash --posix (busybox is not
# needed) on a copy whose /mnt/sdb1 and /etc/init.d/navidrome point to
# scratch. wget calls have a time limit; a failed download leaves no
# archive behind and the deployed binary and ID untouched.
. "$(dirname "$0")/lib.sh"

fixtures="$(cd "$(dirname "$0")/fixtures" && pwd)"
base="$WORK/mnt"
script="$(patched cron/navidrome-update-openwrt-ash \
	"s|^BASE=/mnt/sdb1$|BASE=\"$base\"|" \
	"s|/etc/init.d/navidrome|$STUBS/navidrome-init|g")" || exit 1

mkdir -p "$WORK/release" "$WORK/log"
printf 'new binary\n' > "$WORK/release/navidrome"
tar -czf "$WORK/release.tar.gz" -C "$WORK/release" navidrome

stub pidof 'exit 0'
stub sync 'exit 0'
stub sleep 'exit 0'
stub navidrome-init 'printf "%s\n" "$1" >> "$LOG/init"'
# wget stub: "-O -" is the API request, "-O FILE" the download. HANG makes
# the API request hang unless a timeout (-T) is given; DL_FAIL writes part
# of the file and fails.
stub wget 'out=; timeout=; prev=
for a; do
	[[ "$prev" == -O ]] && out="$a"
	[[ "$prev" == -T ]] && timeout="$a"
	prev="$a"
done
if [[ "$out" == - ]]; then
	if [[ -n "$HANG" ]]; then
		[[ -n "$timeout" ]] && exit 1
		exec "'"$SLEEP_BIN"'" 20
	fi
	cat "$FIXTURES/navidrome-release.json"
elif [[ -n "$DL_FAIL" ]]; then
	printf partial > "$out"; exit 1
else
	cp "$RELEASE_TARBALL" "$out"
fi'

reset_base() {
	rm -rf "$base" "$WORK/tmp" "$WORK/log/init"
	mkdir -p "$base/navidrome" "$base/Music" "$WORK/tmp"
	printf 'old binary\n' > "$base/navidrome/navidrome"
	: > "$base/navidrome/navidrome.db"
	: > "$base/navidrome/navidrome.toml"
	printf 'v0.98.0\n' > "$base/ID"
}

run_update() {
	env FIXTURES="$fixtures" RELEASE_TARBALL="$WORK/release.tar.gz" LOG="$WORK/log" TMPDIR="$WORK/tmp" "$@" \
		"$TIMEOUT_BIN" 10 "$BASH_BIN" --posix "$script" > "$WORK/out" 2>&1
}

reset_base
run_update
rc=$?
check "update: exit 0 (got $rc)" test "$rc" -eq 0
check 'update: new binary deployed' grep -qx 'new binary' "$base/navidrome/navidrome"
check 'update: ID is the new tag' grep -qx 'v0.99.0' "$base/ID"
check 'update: archive removed' test -z "$(ls -A "$WORK/tmp")"

reset_base
run_update HANG=1
rc=$?
check "API does not answer: run ends on its own, exit 0 (got $rc)" test "$rc" -eq 0
check 'API does not answer: ID unchanged' grep -qx 'v0.98.0' "$base/ID"

reset_base
run_update DL_FAIL=1
rc=$?
check "download fails: exit status not 0 (got $rc)" test "$rc" -ne 0
check 'download fails: no partial archive left' test -z "$(ls -A "$WORK/tmp")"
check 'download fails: binary and ID unchanged' grep -qx 'v0.98.0' "$base/ID"
check 'download fails: navidrome not stopped' bash -c '! grep -qs stop "$1"' _ "$WORK/log/init"

done_testing
