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
stub scp 'printf "%s\n" "$@" > "$LOG/scp.args"'
stub ssh 'printf "%s\n" "$@" > "$LOG/ssh.args"'

HOME="$home" USER=nobody-test LOG="$WORK/log" "$ZSH_BIN" "$REPO/openwrt/ruter-upgrade" > "$WORK/out" 2>&1
rc=$?

check 'exit status 0' test "$rc" -eq 0
check 'firmware copied from $HOME/Downloads/openwrt' \
	grep -qxF "$tree/bin/targets/x86/64/openwrt-x86-64-generic-ext4-combined.img" "$WORK/log/scp.args"
check 'sysupgrade sent to the router' grep -qF 'sysupgrade -q /tmp/openwrt-x86-64-generic-ext4-combined.img' "$WORK/log/ssh.args"

done_testing
