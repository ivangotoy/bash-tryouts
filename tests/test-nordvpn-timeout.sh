#!/usr/bin/env bash
# nordvpn/*: a NordVPN API that does not answer must not hang the scripts;
# every curl call has a time limit (--max-time).
. "$(dirname "$0")/lib.sh"

# curl stub for a server that never answers: with --max-time it gives up
# like curl does (exit 28), without it it hangs.
stub curl 'for a; do [[ "$a" == --max-time ]] && exit 28; done
exec "'"$SLEEP_BIN"'" 20'
stub tput 'exit 1'

for script in nordvpn/BG-WG-16-NORDVPN nordvpn/ES-WG-16-NORDVPN nordvpn/NORDVPN-SERVERS; do
	printf '1\n' | "$TIMEOUT_BIN" 10 "$ZSH_BIN" "$REPO/$script" > "$WORK/out" 2>&1
	rc=$?
	check "$script: API timeout ends the run with exit 1 (got $rc)" test "$rc" -eq 1
done

done_testing
