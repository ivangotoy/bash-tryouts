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

done_testing
