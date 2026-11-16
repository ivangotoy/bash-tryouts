#!/usr/bin/env bash
# cron/alerter.sh: one mail per stopped process; a mail that could not be
# sent makes the run fail.
. "$(dirname "$0")/lib.sh"

# alerter.sh sets its own PATH starting with ~/.local/bin: the stubs go there.
home="$WORK/home"
mkdir -p "$home/.local" "$WORK/log"
ln -s "$STUBS" "$home/.local/bin"

stub pidof '[[ " $DOWN " != *" $1 "* ]]'
stub pgrep 'exit 0'
# sendmail stub; HANG: it takes the mail and never ends (an SMTP server
# that stops answering).
stub sendmail 'cat >> "$LOG/mail"; [[ -n "$HANG" ]] && exec "'"$SLEEP_BIN"'" 30; exit "${MAIL_RC:-0}"'
# timeout stub: the real timeout with 2 seconds instead of the script's limit.
stub timeout 'shift; exec "'"$TIMEOUT_BIN"'" 2 "$@"'

run_alerter() {
	rm -f "$WORK/log/mail"
	HOME="$home" LOG="$WORK/log" DOWN="$1" MAIL_RC="$2" HANG="$3" "$TIMEOUT_BIN" 20 "$ZSH_BIN" "$REPO/cron/alerter.sh" > "$WORK/out" 2>&1
}

run_alerter '' 0
check 'all running: exit 0' test $? -eq 0
check 'all running: no mail' test ! -e "$WORK/log/mail"

run_alerter 'nginx' 0
check 'nginx down: exit 0 after the mail was sent' test $? -eq 0
check 'nginx down: mail about nginx' grep -q '^Subject: nginx NOT RUNNING' "$WORK/log/mail"

run_alerter 'nginx' 1
check 'nginx down, sendmail fails: exit 1' test $? -eq 1

run_alerter 'nginx mariadbd' 0 1
rc=$?
check "sendmail hangs: run ends, exit 1 (got $rc)" test "$rc" -eq 1
check 'sendmail hangs: the next alert is still tried' grep -q '^Subject: mariadbd NOT RUNNING' "$WORK/log/mail"

done_testing
