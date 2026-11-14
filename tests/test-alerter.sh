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
stub sendmail 'cat >> "$LOG/mail"; exit "${MAIL_RC:-0}"'

run_alerter() {
	rm -f "$WORK/log/mail"
	HOME="$home" LOG="$WORK/log" DOWN="$1" MAIL_RC="$2" "$ZSH_BIN" "$REPO/cron/alerter.sh" > "$WORK/out" 2>&1
}

run_alerter '' 0
check 'all running: exit 0' test $? -eq 0
check 'all running: no mail' test ! -e "$WORK/log/mail"

run_alerter 'nginx' 0
check 'nginx down: exit 0 after the mail was sent' test $? -eq 0
check 'nginx down: mail about nginx' grep -q '^Subject: nginx NOT RUNNING' "$WORK/log/mail"

run_alerter 'nginx' 1
check 'nginx down, sendmail fails: exit 1' test $? -eq 1

done_testing
