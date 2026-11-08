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
# rg nginx ipset iptables sed
#
# Works nicely in crontab, just keep your nginx access.log available at all times :)
#
# The script creates the ipset hash table "blacklist" and the iptables rule
# when they are missing. To do it by hand:
#
# ipset create blacklist hash:ip
# iptables -I INPUT -m set --match-set blacklist src -j DROP
#
# Every run rebuilds the set from the current access.log and saves it to
# ~/blacklist/ipsets.conf; ~/blacklist/status gets one line per run.

export LC_ALL=C
export LANG=C

log="/var/log/nginx/access.log"
statedir=~/blacklist

# Our own addresses, never banned (rg regex, matched anywhere in the line).
myip="127.0.0.1|192.168.1.1|192.168.1.222|192.168.1.70"

# Request patterns that earn a ban (rg regex).
bad="jndi|system.php|actuator|kerbynet|RadEditorProvider|telerikwebui|Telerik.Web.UI|phpMyAdmin|content-post.php|mide.php|phpunit|HEADER.md|/owa/auth/logon.aspx|main.installer.php|\?author=[0-9]|wp-login.php|logon|getuser|execute|passwd|Nikto|/\.env |nuclei|union|UNION|sql|conf|/[(w|x)]*shell|cmd|Admin|admin|cfg|boaform"

# Clients that are never banned (rg regex).
good="$myip|DuckDuckBot|Adsbot|Googlebot|YandexBot|bingbot|SemrushBot|PetalBot"

if [[ "$EUID" -ne 0 ]]; then
	printf 'This script must be run as root! sudo %s\n' "$0"
	exit 1
fi

if [[ ! -f "$log" ]]; then
	printf '%s not found! If you have one - provide proper location in this script and retry.\n' "$log"
	exit 1
fi

mkdir -p "$statedir"

if ! ipset -q list blacklist &>/dev/null; then
	printf 'Hashtable named blacklist does not exist. Creating it for you.\n'
	ipset create blacklist hash:ip
fi

if ! iptables-save | rg -q -- '--match-set blacklist src'; then
	iptables -I INPUT -m set --match-set blacklist src -j DROP
fi

# Combined log format: field 1 is the client IP, field 9 the status code.
list="$(rg -- "$bad" "$log" | rg -v -- "$good" | cut -d ' ' -f 1,9 | rg ' (301|302|400|403|404|499)$' | cut -d ' ' -f 1 | sort --parallel=4 -n | uniq -i)"

{
	printf 'create blacklist hash:ip family inet hashsize 4096 maxelem 65536 bucketsize 12 initval 0x6084fd11\n'
	[[ -n "$list" ]] && printf 'add blacklist %s\n' ${(f)list}
} > "$statedir/ipsets.conf"

ipset -q flush blacklist
ipset -q restore -! < "$statedir/ipsets.conf" &>/dev/null

printf 'Cron blacklisting status OK - %s\n' "$(date)" >> "$statedir/status"

exit 0
