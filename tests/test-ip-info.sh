#!/usr/bin/env bash
# system/IP-INFO: the LAN address from ip, the public IP over https (a
# plain http answer could be faked on the way), every curl call time limited.
. "$(dirname "$0")/lib.sh"

stub ip 'printf "2: eth0    inet 192.0.2.10/24 brd 192.0.2.255 scope global eth0\\       valid_lft forever preferred_lft forever\n"'
# curl stub: answers only https://checkip.amazonaws.com, and only with a
# time limit (--max-time); anything else fails like curl does.
stub curl 'limit=; for a; do [[ "$a" == --max-time ]] && limit=1; done
[[ -n "$limit" && "${@: -1}" == https://checkip.amazonaws.com ]] || exit 6
printf "198.51.100.1\n"'

"$ZSH_BIN" "$REPO/system/IP-INFO" > "$WORK/out" 2>&1
rc=$?
check "exit 0 (got $rc)" test "$rc" -eq 0
check 'LAN address shown' grep -qx 'MY LOCAL IP IS: 192.0.2.10' "$WORK/out"
check "public IP over https shown (got: $(grep 'PUBLIC' "$WORK/out"))" grep -qx 'MY PUBLIC IP IS: 198.51.100.1' "$WORK/out"

done_testing
