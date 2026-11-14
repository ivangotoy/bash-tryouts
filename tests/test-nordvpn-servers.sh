#!/usr/bin/env bash
# nordvpn/NORDVPN-SERVERS: a failed server list request is an error, not an
# empty table with exit status 0.
. "$(dirname "$0")/lib.sh"

fixtures="$(dirname "$0")/fixtures"
# curl stub: the country list from a fixture; the server list from a
# fixture or, with SERVERS_RC set, a failure like curl --fail (exit 22).
stub curl 'url="${@: -1}"
case $url in
	*/servers/countries) cat "$FIXTURES/nordvpn-countries.json" ;;
	*/servers\?*) [[ -n "$SERVERS_RC" ]] && exit "$SERVERS_RC"; cat "$FIXTURES/nordvpn-servers.json" ;;
	*) exit 6 ;;
esac'

run_servers() {
	printf '1\n' | FIXTURES="$fixtures" SERVERS_RC="$1" "$ZSH_BIN" "$REPO/nordvpn/NORDVPN-SERVERS" > "$WORK/out" 2>&1
}

run_servers ''
check 'server list: exit 0' test $? -eq 0
check 'server list: least loaded server listed' grep -q 'xa7.nordvpn.example' "$WORK/out"

run_servers 22
check 'server list request fails: exit 1' test $? -eq 1

done_testing
