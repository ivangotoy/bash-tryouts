#!/usr/bin/env bash
# cron/blacklist.sh (root only: run as root of a user namespace, on a copy
# whose access.log path points to a fixture). The ban lists are only
# replaced when the new list was built and saved, by loading it into
# temporary sets and swapping those in (the live sets are never flushed);
# any failure leaves the live sets alone, logs FAILED and exits 1.
. "$(dirname "$0")/lib.sh"
need_userns

fixtures="$(cd "$(dirname "$0")/fixtures" && pwd)"
script="$(patched cron/blacklist.sh "s|^log=\"/var/log/nginx/access.log\"|log=\"$fixtures/nginx-access.txt\"|")" || exit 1
home="$WORK/home"
state="$home/blacklist"
mkdir -p "$home" "$WORK/log"

# ipset stub: logs every call; keeps what restore reads; NOSETS: the live
# sets do not exist yet; RESTORE_RC / SWAP6_RC: make restore or the IPv6
# swap fail. restore reads at most 100 kB (stdin may be /dev/full).
stub ipset 'printf "%s\n" "$*" >> "$LOG/ipset"
case " $* " in
	*" restore "*) head -c 100000 > "$LOG/restore.in"; exit "${RESTORE_RC:-0}" ;;
	*" swap blacklist6-new blacklist6 "*) exit "${SWAP6_RC:-0}" ;;
	*" list "*) [[ -z "$NOSETS" ]]; exit ;;
esac
exit 0'
stub iptables-save 'printf -- "-A INPUT -m set --match-set blacklist src -j DROP\n"'
stub ip6tables-save 'printf -- "-A INPUT -m set --match-set blacklist6 src -j DROP\n"'
stub iptables 'printf "%s\n" "$*" >> "$LOG/iptables"'
stub ip6tables 'printf "%s\n" "$*" >> "$LOG/iptables"'

run_blacklist() {
	rm -f "$WORK/log/ipset" "$WORK/log/restore.in"
	HOME="$home" LOG="$WORK/log" "$@" "$UNSHARE_BIN" -r "$ZSH_BIN" "$script" > "$WORK/out" 2>&1
}

ipset_log() { grep -cE "$1" "$WORK/log/ipset" 2>/dev/null; }
# The live sets are emptied or removed by flush/destroy, or filled by a
# restore that names them.
live_untouched() {
	[[ "$(ipset_log '(^| )(flush|destroy) blacklist6?$')" == 0 ]] &&
		! grep -qE '^(create|add) blacklist6? ' "$WORK/log/restore.in" 2>/dev/null
}
last_status() { tail -n 1 "$state/status"; }

run_blacklist env
rc=$?
check "rebuild: exit 0 (got $rc)" test "$rc" -eq 0
check 'rebuild: probing IPv4 client banned' grep -qx 'add blacklist 203.0.113.5' "$state/ipsets.conf"
check 'rebuild: probing IPv6 client banned' grep -qx 'add blacklist6 2001:db8::5' "$state/ipsets.conf"
check 'rebuild: whitelisted, clean and User-Agent-only clients not banned' \
	test "$(grep -c '^add ' "$state/ipsets.conf")" -eq 2
check 'rebuild: temporary sets get ipsets.conf with only the set names changed' \
	test "$(sed -E 's/^(create|add) (blacklist6?) /\1 \2-new /' "$state/ipsets.conf")" = "$(cat "$WORK/log/restore.in")"
check 'rebuild: live sets never flushed or destroyed' live_untouched
check 'rebuild: IPv4 set swapped in' test "$(ipset_log 'swap blacklist-new blacklist$')" = 1
check 'rebuild: IPv6 set swapped in' test "$(ipset_log 'swap blacklist6-new blacklist6$')" = 1
check 'rebuild: temporary sets destroyed' test "$(ipset_log 'destroy blacklist6?-new$')" -ge 2
check 'rebuild: status OK' grep -q '^Cron blacklisting status OK' <(last_status)

run_blacklist env NOSETS=1
rc=$?
check "first run: exit 0 (got $rc)" test "$rc" -eq 0
check 'first run: live sets created' test "$(ipset_log '^create blacklist6? hash:ip')" = 2
check 'first run: swapped in' test "$(ipset_log 'swap blacklist6?-new blacklist6?$')" = 2

run_blacklist env RESTORE_RC=1
rc=$?
check "ipset restore fails: exit 1 (got $rc)" test "$rc" -eq 1
check 'ipset restore fails: nothing swapped' test "$(ipset_log ' swap ')" = 0
check 'ipset restore fails: live sets untouched' live_untouched
check 'ipset restore fails: temporary sets destroyed' test "$(ipset_log 'destroy blacklist6?-new$')" -ge 2
check 'ipset restore fails: FAILED status line' grep -q 'status FAILED' <(last_status)

run_blacklist env SWAP6_RC=1
rc=$?
check "IPv6 swap fails: exit 1 (got $rc)" test "$rc" -eq 1
check 'IPv6 swap fails: IPv4 set swapped back' test "$(ipset_log 'swap blacklist-new blacklist$')" = 2
check 'IPv6 swap fails: live sets untouched' live_untouched
check 'IPv6 swap fails: FAILED status line' grep -q 'status FAILED' <(last_status)

# awk cannot read the log: the sets are not touched.
stub awk 'exit 2'
run_blacklist env
rc=$?
rm -f "$STUBS/awk"
check "log not parsed: exit 1 (got $rc)" test "$rc" -eq 1
check 'log not parsed: no restore or swap' test "$(ipset_log ' (restore|swap|flush) ')" = 0

# ipsets.conf cannot be written (full disk): the sets are not touched.
rm -f "$state/ipsets.conf"
ln -s /dev/full "$state/ipsets.conf"
run_blacklist env
rc=$?
rm -f "$state/ipsets.conf"
check "ipsets.conf not written: exit 1 (got $rc)" test "$rc" -eq 1
check 'ipsets.conf not written: no restore or swap' test "$(ipset_log ' (restore|swap|flush) ')" = 0

done_testing
