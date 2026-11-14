#!/usr/bin/env bash
# nordvpn/BG-WG-16-NORDVPN, ES-WG-16-NORDVPN, NORDVPN-SERVERS: each server
# has several technologies and some carry metadata other than the WireGuard
# key (proxy_hostname, port). The rows must show hostname, IP, the
# WireGuard public key and the load, in that order (COLUMNS=200: no
# wrapping by column -W in NORDVPN-SERVERS).
. "$(dirname "$0")/lib.sh"

fixtures="$(cd "$(dirname "$0")/fixtures" && pwd)"
stub curl 'case ${@: -1} in
	*/servers/countries) cat "$FIXTURES/nordvpn-countries.json" ;;
	*/servers\?*) cat "$FIXTURES/nordvpn-servers.json" ;;
	*) exit 6 ;;
esac'
stub tput 'exit 1'

for script in nordvpn/BG-WG-16-NORDVPN nordvpn/ES-WG-16-NORDVPN nordvpn/NORDVPN-SERVERS; do
	printf '1\n' | COLUMNS=200 FIXTURES="$fixtures" "$ZSH_BIN" "$REPO/$script" > "$WORK/out" 2>&1
	rc=$?
	check "$script: exit 0 (got $rc)" test "$rc" -eq 0
	row="$(grep -m1 'xa7.nordvpn.example' "$WORK/out" | tr -s ' ')"
	check "$script: row is host, IP, public key, load (got: $row)" \
		test "$row" = 'xa7.nordvpn.example 192.0.2.7 BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB= 9'
done

done_testing
