#!/usr/bin/env bash
# cron/blacklist.sh (root only: run as root of a user namespace, on a copy
# whose access.log path points to a fixture). The ban lists are only
# replaced when the new list was built and saved; a failed restore is an
# error, not "status OK".
. "$(dirname "$0")/lib.sh"
need_userns

fixtures="$(cd "$(dirname "$0")/fixtures" && pwd)"
script="$(patched cron/blacklist.sh "s|^log=\"/var/log/nginx/access.log\"|log=\"$fixtures/nginx-access.txt\"|")" || exit 1
home="$WORK/home"
state="$home/blacklist"
mkdir -p "$home" "$WORK/log"

stub ipset 'printf "%s\n" "$*" >> "$LOG/ipset"
[[ " $* " == *" restore "* ]] && exit "${RESTORE_RC:-0}"
exit 0'
stub iptables-save 'printf -- "-A INPUT -m set --match-set blacklist src -j DROP\n"'
stub ip6tables-save 'printf -- "-A INPUT -m set --match-set blacklist6 src -j DROP\n"'
stub iptables 'printf "%s\n" "$*" >> "$LOG/iptables"'
stub ip6tables 'printf "%s\n" "$*" >> "$LOG/iptables"'

run_blacklist() {
	rm -f "$WORK/log/ipset"
	HOME="$home" LOG="$WORK/log" RESTORE_RC="$1" "$UNSHARE_BIN" -r "$ZSH_BIN" "$script" > "$WORK/out" 2>&1
}

run_blacklist 0
rc=$?
check "rebuild: exit 0 (got $rc)" test "$rc" -eq 0
check 'rebuild: probing IPv4 client banned' grep -qx 'add blacklist 203.0.113.5' "$state/ipsets.conf"
check 'rebuild: probing IPv6 client banned' grep -qx 'add blacklist6 2001:db8::5' "$state/ipsets.conf"
check 'rebuild: whitelisted, clean and User-Agent-only clients not banned' \
	test "$(grep -c '^add ' "$state/ipsets.conf")" -eq 2
check 'rebuild: sets flushed and restored' grep -q 'restore' "$WORK/log/ipset"
check 'rebuild: status OK' grep -q '^Cron blacklisting status OK' "$state/status"

run_blacklist 1
rc=$?
check "ipset restore fails: exit 1 (got $rc)" test "$rc" -eq 1
check 'ipset restore fails: no OK status line' test "$(tail -n 1 "$state/status" | grep -c 'status OK')" -eq 0

# awk cannot read the log: the sets must not be flushed.
stub awk 'exit 2'
run_blacklist 0
rc=$?
rm -f "$STUBS/awk"
check "log not parsed: exit 1 (got $rc)" test "$rc" -eq 1
check 'log not parsed: sets not flushed' test "$(grep -c flush "$WORK/log/ipset")" -eq 0

# ipsets.conf cannot be written (full disk): the sets must not be flushed.
rm -f "$state/ipsets.conf"
ln -s /dev/full "$state/ipsets.conf"
run_blacklist 0
rc=$?
rm -f "$state/ipsets.conf"
check "ipsets.conf not written: exit 1 (got $rc)" test "$rc" -eq 1
check 'ipsets.conf not written: sets not flushed' test "$(grep -c flush "$WORK/log/ipset")" -eq 0

done_testing
