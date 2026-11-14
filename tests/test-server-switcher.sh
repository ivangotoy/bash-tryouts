#!/usr/bin/env bash
# nordvpn/SERVER-SWITCHER (root only: run as root of a user namespace, on a
# copy whose config path points to a fixture).
. "$(dirname "$0")/lib.sh"
need_userns

conf="$WORK/bg.conf"
script="$(patched nordvpn/SERVER-SWITCHER "s|^file=\"/etc/wireguard/bg.conf\"|file=\"$conf\"|")" || exit 1
mkdir -p "$WORK/log"
stub systemctl 'printf "%s\n" "$*" >> "$LOG/systemctl"'
stub tput 'exit 1'

run_switcher() {
	cp "$REPO/nordvpn/bg.conf" "$conf"
	LOG="$WORK/log" "$TIMEOUT_BIN" 10 "$UNSHARE_BIN" -r "$ZSH_BIN" "$script" > "$WORK/out" 2>&1
}

# API that never answers: with --max-time curl gives up (exit 28).
stub curl 'for a; do [[ "$a" == --max-time ]] && exit 28; done
exec "'"$SLEEP_BIN"'" 20'
run_switcher
rc=$?
check "API timeout: exit 1 (got $rc)" test "$rc" -eq 1
check 'API timeout: config unchanged' cmp -s "$REPO/nordvpn/bg.conf" "$conf"

# API answer from a fixture: bg7 is the least loaded server.
stub curl 'case ${@: -1} in
	*/v1/servers\?*) cat "$FIXTURES/nordvpn-servers-bg.json" ;;
	checkip.amazonaws.com) printf "198.51.100.1\n" ;;
	*) exit 6 ;;
esac'
FIXTURES="$(dirname "$0")/fixtures"
export FIXTURES

rm -f "$WORK/log/systemctl"
run_switcher
rc=$?
check "switch: exit 0 (got $rc)" test "$rc" -eq 0
check 'switch: Endpoint is bg7' grep -qx 'Endpoint = bg7.nordvpn.com:51820' "$conf"
check 'switch: PublicKey of bg7' grep -qx 'PublicKey = BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB=' "$conf"
check 'switch: wg-quick@bg restarted' grep -qx 'restart wg-quick@bg' "$WORK/log/systemctl"

# The config cannot be edited (e.g. read-only /etc): no restart, exit 1.
stub sed 'exit 4'
rm -f "$WORK/log/systemctl"
run_switcher
rc=$?
rm -f "$STUBS/sed"
check "config edit fails: exit 1 (got $rc)" test "$rc" -eq 1
check 'config edit fails: no restart' test ! -e "$WORK/log/systemctl"

done_testing
