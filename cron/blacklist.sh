#!/usr/bin/env bash
#
# Ivan Angelov ivangotoy@gmail.com
# https://digtvbg.com/
#
# This is a bash script that tries to "ban" some of the bad clients on your nginx webserver.
# 
# Tooling used:
# 
# - rg nginx ipset iptables
# 
# Works nicely in crontab, just keep your nginx.log populated at all times :)
#
# Feel free to create a hashtable called blacklist in ipset too... or bother to read below.
#
# Create ipset hashtable/set called "blacklist" with this command:
#
# ipset create (-N is like create too) blacklist hash:ip
#
# Make iptables do the right thing with your newly created hashtable called "blacklist":
#
# iptables -I INPUT -m set --match-set blacklist src -j DROP
#
# Save you iptables rules and populate your blacklist hastabled.

export LC_ALL=C
export LANG=C

log="/var/log/nginx/access.log"
myip="127.0.0.1|192.168.1.1|192.168.1.222|78.130.248.61|192.168.1.70"
list="$(rg 'wp-login.php|logon|getuser|execute|passwd|Nikto|/\.env |nuclei|union|UNION|sql|conf|/[(w|x)]*shell|cmd|Admin|admin|cfg|boaform' "$log" | rg -v "$myip|DuckDuckBot|Adsbot|Googlebot|YandexBot|bingbot|SemrushBot|PetalBot" | cut -d ' ' -f 1,9 | rg '301|302|400|403|404|499' | cut -d ' ' -f 1 | sort --parallel=4 -n | uniq -i)"

ipset -q restore -! < /etc/ipsets.conf &> /dev/null
ipset -q flush blacklist &> /dev/null
for badip in $list
do
ipset -q -A blacklist "$badip"
done

ipset -q save blacklist -f /etc/ipsets.conf &> /dev/null
printf "Cron status OK - $(date)\n" >> /home/$USER/blacklist/status
