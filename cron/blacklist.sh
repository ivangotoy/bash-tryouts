#!/usr/bin/env zsh
#
# Ivan Angelov ivangotoy@gmail.com
#
# https://digtvbg.com/
#
# This is a zsh script that tries to ban some of the bad clients on your nginx webserver.
#
# After we make sure it works for us we can add it to root crontab.
#
# Tooling used:
#
# rg awk nginx ipset iptables ip6tables
#
# Works nicely in crontab, just keep your nginx access.log available at all times :)
#
# The script creates the ipset hash tables "blacklist" (IPv4) and
# "blacklist6" (IPv6) and their iptables/ip6tables rules when they are
# missing. To do it by hand:
#
# ipset create blacklist hash:ip
# ipset create blacklist6 hash:ip family inet6
# iptables -I INPUT -m set --match-set blacklist src -j DROP
# ip6tables -I INPUT -m set --match-set blacklist6 src -j DROP
#
# Every run rebuilds the set from the current access.log and saves it to
# ~/blacklist/ipsets.conf; ~/blacklist/status gets one line per run.

export LC_ALL=C
export LANG=C
setopt pipefail

log="/var/log/nginx/access.log"
statedir=~/blacklist

# Our own addresses, never banned. Exact match on the client IP (field 1)
# only, so a User-Agent or URL that contains one of them does not count.
myip=(127.0.0.1 ::1 192.168.1.1 192.168.1.222 192.168.1.70)

# Request patterns that earn a ban (awk ERE). They are matched against the
# request target (path and query string) only, not the whole log line.
bad='jndi|system.php|actuator|kerbynet|RadEditorProvider|telerikwebui|Telerik.Web.UI|phpMyAdmin|content-post.php|mide.php|phpunit|HEADER.md|/owa/auth/logon.aspx|main.installer.php|\?author=[0-9]|wp-login.php|logon|getuser|execute|passwd|Nikto|/\.env($|\?)|nuclei|union|UNION|sql|conf|/[(w|x)]*shell|cmd|Admin|admin|cfg|boaform'

# Only requests answered with one of these status codes earn a ban.
codes=(301 302 400 403 404 499)

if [[ "$EUID" -ne 0 ]]; then
	printf 'This script must be run as root! sudo %s\n' "$0"
	exit 1
fi

if [[ ! -f "$log" ]]; then
	printf '%s not found! If you have one - provide proper location in this script and retry.\n' "$log"
	exit 1
fi

mkdir -p "$statedir"

# IPv4 clients go to "blacklist", IPv6 clients to "blacklist6".

if ! ipset -q list blacklist &>/dev/null; then
	printf 'Hashtable named blacklist does not exist. Creating it for you.\n'
	ipset create blacklist hash:ip
fi

if ! ipset -q list blacklist6 &>/dev/null; then
	printf 'Hashtable named blacklist6 does not exist. Creating it for you.\n'
	ipset create blacklist6 hash:ip family inet6
fi

if ! iptables-save | rg -q -- '--match-set blacklist src'; then
	iptables -I INPUT -m set --match-set blacklist src -j DROP
fi

if ! ip6tables-save | rg -q -- '--match-set blacklist6 src'; then
	ip6tables -I INPUT -m set --match-set blacklist6 src -j DROP
fi

# Combined log format, split on double quotes (nginx escapes quotes inside
# fields as \x22): $1 = 'IP - user [date] ', $2 = 'METHOD TARGET PROTO',
# $3 = ' STATUS BYTES '. One line per banned IP.
# The sets are only replaced once the new list was read and saved.
if ! list="$(GOOD="${(j: :)myip}" CODES="${(j: :)codes}" BAD="$bad" awk -F '"' '
BEGIN {
	n = split(ENVIRON["GOOD"], g, " "); for (i = 1; i <= n; i++) good[g[i]] = 1
	n = split(ENVIRON["CODES"], c, " "); for (i = 1; i <= n; i++) code[c[i]] = 1
	bad = ENVIRON["BAD"]
}
{
	split($1, a, " "); ip = a[1]
	split($2, r, " "); target = r[2]
	split($3, st, " "); status = st[1]
	if (ip == "" || (ip in good) || (ip in seen) || !(status in code)) next
	if (target ~ bad) { seen[ip] = 1; print ip }
}' "$log" | sort)"; then
	printf 'Could not read %s, the ban lists were not changed.\n' "$log" >&2
	exit 1
fi

ips=(${(f)list})
v6=(${(M)ips:#*:*})
v4=(${ips:#*:*})

# One print, so its exit status covers the whole file.
if ! print -rl -- \
	'create blacklist hash:ip family inet hashsize 4096 maxelem 65536 bucketsize 12 initval 0x6084fd11' \
	'create blacklist6 hash:ip family inet6 hashsize 4096 maxelem 65536' \
	${v4/#/add blacklist } ${v6/#/add blacklist6 } > "$statedir/ipsets.conf"; then
	printf 'Could not write %s, the ban lists were not changed.\n' "$statedir/ipsets.conf" >&2
	exit 1
fi

ipset -q flush blacklist
ipset -q flush blacklist6
if ! ipset -q restore -! < "$statedir/ipsets.conf" &>/dev/null; then
	printf 'Cron blacklisting status FAILED (ipset restore) - %s\n' "$(date)" >> "$statedir/status"
	printf 'ipset restore from %s failed, check: ipset list blacklist blacklist6\n' "$statedir/ipsets.conf" >&2
	exit 1
fi

printf 'Cron blacklisting status OK - %s\n' "$(date)" >> "$statedir/status"

exit 0
