#!/usr/bin/env bash
# cron/UPDATE-WAF-CORERULESETS-CRONJOB (on a copy whose repo and log paths
# point to scratch): a failed nginx reload after an update is an error; the
# pre-move log ~/alerter/coreruleset-updates is moved into the log once.
. "$(dirname "$0")/lib.sh"

repo="$WORK/coreruleset"
logfile="$WORK/coreruleset-updates.txt"
mkdir -p "$repo" "$WORK/log"
script="$(patched cron/UPDATE-WAF-CORERULESETS-CRONJOB \
	"s|^repo=\"/etc/nginx/modsec/coreruleset/\"|repo=\"$repo/\"|" \
	"s|^logfile=\"/var/log/coreruleset-updates.log\"|logfile=\"$logfile\"|" \
	"s|\"/home/\$USER/alerter/coreruleset-updates\"|\"$WORK/oldhome/alerter/coreruleset-updates\"|")" || exit 1
olddir="$WORK/oldhome/alerter"
oldlog="$olddir/coreruleset-updates"

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

# Pre-move log: appended to the log, then removed with its empty directory.
mkdir -p "$olddir"
printf 'Mon Jan  5 03:00:00 UTC 2026 Just another CRONJOB run - no updates!\n\n' > "$oldlog"
cp "$oldlog" "$WORK/old.copy"
run_waf 0
rc=$?
check "old log: update still runs, exit 0 (got $rc)" test "$rc" -eq 0
check 'old log: its lines come first in the log' \
	test "$(head -n 2 "$logfile" 2>/dev/null)" = "$(cat "$WORK/old.copy")"
check 'old log: new entry after it' grep -q 'Coreruleset updated from git' "$logfile"
check 'old log: removed' test ! -e "$oldlog"
check 'old log: empty directory removed' test ! -e "$olddir"

# Second run: nothing left to move, the log just grows by the new entry.
cp "$logfile" "$WORK/log.before"
LOG="$WORK/log" "$ZSH_BIN" "$script" > "$WORK/out" 2>&1
check 'second run: old lines not added again' test "$(grep -c 'Mon Jan  5' "$logfile")" = 1
check 'second run: log only appended to' test "$(head -c "$(stat -c %s "$WORK/log.before")" "$logfile")" = "$(cat "$WORK/log.before")"

# Directory with other files: the old log goes, the directory stays.
mkdir -p "$olddir"
printf 'old\n' > "$oldlog"
: > "$olddir/other"
run_waf 0
check 'old log, other files: directory kept' test -e "$olddir/other" -a ! -e "$oldlog"
rm -rf "$olddir"

# The append fails (full disk): old log kept, warning, update still runs.
mkdir -p "$olddir"
printf 'old\n' > "$oldlog"
rm -f "$WORK/log/systemctl"
LOG="$WORK/log" "$ZSH_BIN" "$(sed "s|^logfile=.*|logfile=/dev/full|" "$script" > "$WORK/full.zsh"; echo "$WORK/full.zsh")" > "$WORK/out" 2>&1
check 'append fails: old log kept' grep -qx old "$oldlog"
check 'append fails: warning printed' grep -q "Could not move $oldlog" "$WORK/out"
check 'append fails: update still ran' grep -qx 'reload nginx' "$WORK/log/systemctl"
rm -rf "$olddir"

# Not a regular file (a directory of that name): left alone.
mkdir -p "$oldlog"
run_waf 0
check 'old log is a directory: left alone' test -d "$oldlog"
rm -rf "$olddir"

done_testing
