#!/usr/bin/env bash
#
# Ivan Angelov ivangotoy@gmail.com
# https://digtvbg.com/
#
# This is a bash script that tries to "ban" some of the bad clients on your nginx webserver.
# 
# Tooling used:
# 
# - rg nginx ipset
# 
# Works nicely in crontab, just keep your nginx.log populated at all times :)
#
# Feel free to create a hashtable called blacklist in ipset too :)
#

export LC_ALL=C
export LANG=C

log="/var/log/nginx/access.log"
myip="127.0.0.1|192.168.1.1|192.168.1.222|78.130.248.61|192.168.1.70"
list="$(rg 'Nikto|/\.env |nuclei|union|UNION|sql|conf|/[(w|x)]*shell|cmd|Admin|admin|cfg' "$log" | rg -v "$myip|DuckDuckBot|Adsbot|Googlebot|YandexBot|bingbot|SemrushBot|PetalBot" | cut -d ' ' -f 1,9 | rg '301|302|400|403|404|499' | cut -d ' ' -f 1 | sort --parallel=4 -n | uniq -i)"

ipset -q restore -! < /etc/ipsets.conf &> /dev/null
ipset -q flush blacklist &> /dev/null
for badip in $list
do
ipset -q -A blacklist "$badip"
done

ipset -q save blacklist -f /etc/ipsets.conf &> /dev/null
printf "Cron status OK - $(date)\n" >> /home/$USER/blacklist/status
