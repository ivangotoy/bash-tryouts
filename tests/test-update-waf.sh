#!/usr/bin/env bash
# cron/UPDATE-WAF-CORERULESETS-CRONJOB (on a copy whose repo and log paths
# point to scratch): a failed nginx reload after an update is an error.
. "$(dirname "$0")/lib.sh"

repo="$WORK/coreruleset"
logfile="$WORK/coreruleset-updates.txt"
mkdir -p "$repo" "$WORK/log"
script="$(patched cron/UPDATE-WAF-CORERULESETS-CRONJOB \
	"s|^repo=\"/etc/nginx/modsec/coreruleset/\"|repo=\"$repo/\"|" \
	"s|^logfile=\"/var/log/coreruleset-updates.log\"|logfile=\"$logfile\"|")" || exit 1

# git stub: the checkout is one commit behind its upstream origin/main.
stub git 'case "$*" in
	"fetch -q"|"pull -q") exit 0 ;;
	"rev-parse --abbrev-ref @{upstream}") printf "origin/main\n" ;;
	"rev-parse HEAD") printf "1111111111111111111111111111111111111111\n" ;;
	"rev-parse origin/main") printf "2222222222222222222222222222222222222222\n" ;;
	*) exit 1 ;;
esac'
stub sync 'exit 0'
stub systemctl 'printf "%s\n" "$*" >> "$LOG/systemctl"; exit "${RELOAD_RC:-0}"'

run_waf() {
	rm -f "$logfile"
	LOG="$WORK/log" RELOAD_RC="$1" "$ZSH_BIN" "$script" > "$WORK/out" 2>&1
}

run_waf 0
rc=$?
check "update: exit 0 (got $rc)" test "$rc" -eq 0
check 'update: nginx reloaded' grep -qx 'reload nginx' "$WORK/log/systemctl"
check 'update: logged' grep -q 'Coreruleset updated from git' "$logfile"

run_waf 1
rc=$?
check "update, reload fails: exit 1 (got $rc)" test "$rc" -eq 1
check 'update, reload fails: logged as a failure' grep -q 'reload failed' "$logfile"

done_testing
