#!/usr/bin/env bash
# cron/PROTIP-DNS-ADBLOCK-ADVICE.txt: the suggested cron command must not
# replace the block list with an error page or a partial download. The
# command is taken from the file, its paths rewritten to scratch.
. "$(dirname "$0")/lib.sh"

etc="$WORK/etc"
mkdir -p "$etc/dnscrypt-proxy2" "$etc/init.d" "$WORK/log"
cmd="$(sed -n 's/^@daily //p' "$REPO/cron/PROTIP-DNS-ADBLOCK-ADVICE.txt")"
cmd="${cmd//\/etc\//$etc/}"
[[ "$cmd" == *"$etc/dnscrypt-proxy2/blocked-names.txt"* ]] || { not_ok 'cron command found in the advice'; done_testing; }
printf '#!%s\nprintf "%%s\\n" "$1" >> "%s"\n' "$BASH_BIN" "$WORK/log/restart" > "$etc/init.d/dnscrypt-proxy"
chmod +x "$etc/init.d/dnscrypt-proxy"

stub sync 'exit 0'
stub sleep 'exit 0'
# curl stub like curl on an HTTP 404: the error page goes to -o; with -f
# (--fail) nothing is written and the exit status is 22.
stub curl 'out=; fail=; prev=
for a; do
	[[ "$prev" == -o ]] && out="$a"
	[[ "$a" == --fail || "$a" =~ ^-[A-Za-z]*f[A-Za-z]*$ ]] && fail=1
	prev="$a"
done
if [[ -n "$OK" ]]; then printf "ads.example.com\n" > "$out"; exit 0; fi
[[ -n "$fail" ]] && exit 22
printf "<html>404 Not Found</html>\n" > "$out"'

list="$etc/dnscrypt-proxy2/blocked-names.txt"

printf 'old.example.com\n' > "$list"
OK=1 "$BASH_BIN" -c "$cmd" > "$WORK/out" 2>&1
check 'download works: list replaced' grep -qx 'ads.example.com' "$list"
check 'download works: dnscrypt-proxy restarted' grep -qx restart "$WORK/log/restart"

printf 'old.example.com\n' > "$list"
rm -f "$WORK/log/restart"
"$BASH_BIN" -c "$cmd" > "$WORK/out" 2>&1
check 'HTTP error: list kept' grep -qx 'old.example.com' "$list"
check 'HTTP error: no restart' test ! -e "$WORK/log/restart"

done_testing
