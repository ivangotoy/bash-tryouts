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
# rg awk sed nginx ipset iptables ip6tables
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
# ~/blacklist/ipsets.conf, loads it into the temporary sets blacklist-new
# and blacklist6-new and swaps those with the live sets (no moment without
# bans); ~/blacklist/status gets one line per run and keeps its newest
# 1000 lines.

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
# Dots in file names are escaped (\. matches a dot only); the value reaches
# awk unchanged through ENVIRON, so one backslash is what awk sees.
bad='jndi|system\.php|actuator|kerbynet|RadEditorProvider|telerikwebui|Telerik\.Web\.UI|phpMyAdmin|content-post\.php|mide\.php|phpunit|HEADER\.md|/owa/auth/logon\.aspx|main\.installer\.php|\?author=[0-9]|wp-login\.php|logon|getuser|execute|passwd|Nikto|/\.env($|\?)|nuclei|union|UNION|sql|conf|/(w|x)?shell|cmd|Admin|admin|cfg|boaform'

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

# Load the new lists into temporary sets (ipsets.conf with the set names
# renamed to blacklist-new / blacklist6-new) and swap them in, so the live
# sets are never empty. On any failure the live sets keep their old content.
destroy_new() {
	ipset -q destroy blacklist-new &>/dev/null
	ipset -q destroy blacklist6-new &>/dev/null
}

# trim_log FILE MAX: keep only the newest MAX lines of FILE. Written to a
# temp file in the same directory and moved over FILE (atomic, same mode);
# on any failure the temp file is removed and FILE stays as it was.
trim_log() {
	local file="$1" max="$2" tmp
	[[ -f "$file" ]] && (( $(wc -l < "$file") > max )) || return 0
	if tmp="$(mktemp "$file.XXXXXX")" && tail -n "$max" "$file" > "$tmp" &&
		chmod --reference="$file" "$tmp" && mv -f "$tmp" "$file"; then
		return 0
	fi
	[[ -n "$tmp" ]] && rm -f "$tmp"
	printf 'Could not trim %s to its last %s lines, left as it was.\n' "$file" "$max" >&2
	return 1
}

# status_line TEXT: one line in ~/blacklist/status, which keeps its newest 1000 lines.
status_line() {
	printf 'Cron blacklisting status %s - %s\n' "$1" "$(date)" >> "$statedir/status"
	trim_log "$statedir/status" 1000
}

# fail STEP: drop the temporary sets, log FAILED, exit 1.
fail() {
	destroy_new
	status_line "FAILED ($1)"
	printf 'Updating the ban lists failed at %s, the live sets were not changed. Check: ipset list blacklist blacklist6\n' "$1" >&2
	exit 1
}

# Leftovers of an interrupted run.
destroy_new

sed -E 's/^(create|add) (blacklist6?) /\1 \2-new /' "$statedir/ipsets.conf" | ipset -q restore -! &>/dev/null ||
	fail 'ipset restore'
ipset -q swap blacklist-new blacklist &>/dev/null || fail 'ipset swap'
if ! ipset -q swap blacklist6-new blacklist6 &>/dev/null; then
	# Put the old IPv4 list back so both sets stay as they were.
	ipset -q swap blacklist-new blacklist &>/dev/null
	fail 'ipset swap'
fi
destroy_new

status_line OK

exit 0
