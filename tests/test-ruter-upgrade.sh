#!/usr/bin/env bash
# openwrt/ruter-upgrade: the OpenWrt tree is ~/Downloads/openwrt, i.e. under
# $HOME, not /home/$USER.
. "$(dirname "$0")/lib.sh"

home="$WORK/home"
tree="$home/Downloads/openwrt"
mkdir -p "$tree/scripts" "$WORK/log"
printf '#!%s\nexit 0\n' "$BASH_BIN" > "$tree/scripts/feeds"
chmod +x "$tree/scripts/feeds"

stub wget 'exit 0'
stub git 'exit 0'
stub nproc 'printf "4\n"'
stub sync 'exit 0'
stub sleep 'exit 0'
stub make '[[ "$1" == clean ]] && exit 0
mkdir -p bin/targets/x86/64 && : > bin/targets/x86/64/openwrt-x86-64-generic-ext4-combined.img'
# scp/ssh stubs for a router that stops answering: they give up only when
# both a connect timeout and a keepalive limit are set, else they hang.
limits='c=; a=; for x; do [[ "$x" == ConnectTimeout=* ]] && c=1; [[ "$x" == ServerAliveInterval=* ]] && a=1; done
[[ -n "$c" && -n "$a" ]] || exec "'"$SLEEP_BIN"'" 20'
stub scp "printf '%s\n' \"\$@\" > \"\$LOG/scp.args\"; [[ -n \"\$HANG_SCP\" ]] && { $limits; exit 1; }; exit 0"
stub ssh "printf '%s\n' \"\$@\" > \"\$LOG/ssh.args\"; [[ -n \"\$HANG_SSH\" ]] && { $limits; exit 255; }; exit 0"

HOME="$home" USER=nobody-test LOG="$WORK/log" "$ZSH_BIN" "$REPO/openwrt/ruter-upgrade" > "$WORK/out" 2>&1
rc=$?

check 'exit status 0' test "$rc" -eq 0
check 'firmware copied from $HOME/Downloads/openwrt' \
	grep -qxF "$tree/bin/targets/x86/64/openwrt-x86-64-generic-ext4-combined.img" "$WORK/log/scp.args"
check 'sysupgrade sent to the router' grep -qF 'sysupgrade -q /tmp/openwrt-x86-64-generic-ext4-combined.img' "$WORK/log/ssh.args"

# The router does not answer the copy: the run ends on its own (exit 1).
HOME="$home" USER=nobody-test LOG="$WORK/log" HANG_SCP=1 "$TIMEOUT_BIN" 10 "$ZSH_BIN" "$REPO/openwrt/ruter-upgrade" > "$WORK/out" 2>&1
rc=$?
check "router does not answer scp: exit 1 (got $rc)" test "$rc" -eq 1

# The ssh session to the rebooting router goes silent: the run goes on to
# the online check (exit 0) instead of hanging.
HOME="$home" USER=nobody-test LOG="$WORK/log" HANG_SSH=1 "$TIMEOUT_BIN" 10 "$ZSH_BIN" "$REPO/openwrt/ruter-upgrade" > "$WORK/out" 2>&1
rc=$?
check "ssh session goes silent: run ends, exit 0 (got $rc)" test "$rc" -eq 0

done_testing
