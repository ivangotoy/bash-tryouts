#!/usr/bin/env bash
#
# Ivan Angelov ivangotoy@gmail.com
# https://digtvbg.com/
#
# This is a bash script that tries to "ban" some of the bad clients on your nginx webserver.
#
# After we make sure it works for us we can add it to root crontab.
#
# Tooling used:
# 
# - rg nginx ipset iptables
# 
# Works nicely in crontab, just keep your nginx access.log available at all times :)
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
# Save you iptables rules and populate your blacklist hastable.

export LC_ALL=C
export LANG=C

log="/var/log/nginx/access.log"
myip="127.0.0.1|192.168.1.1|192.168.1.222|78.130.248.61|192.168.1.70"
list="$(rg 'content-post.php|mide.php|phpunit|HEADER.md|/owa/auth/logon.aspx|main.installer.php|\?author=[0-9]|wp-login.php|logon|getuser|execute|passwd|Nikto|/\.env |nuclei|union|UNION|sql|conf|/[(w|x)]*shell|cmd|Admin|admin|cfg|boaform' "$log" | rg -v "$myip|DuckDuckBot|Adsbot|Googlebot|YandexBot|bingbot|SemrushBot|PetalBot" | cut -d ' ' -f 1,9 | rg '301|302|400|403|404|499' | cut -d ' ' -f 1 | sort --parallel=4 -n | uniq -i)"

if [[ "$EUID" -ne 0 ]]; then
printf "This script must be run as root! sudo $0 \n"
exit 1
fi

if [[ ! -d /home/$USER/blacklist ]];
then
mkdir -p /home/$USER/blacklist
touch /home/$USER/blacklist/status
fi

if [[ ! -f "$log" ]];
then
printf "$log not found! If you have one - provide proper location in this script and retry.\n"
exit 1
fi

if [[ -f /etc/ipsets.conf ]];
then
ipset -q restore -! < /etc/ipsets.conf &> /dev/null
fi

ipset -q list blacklist &> /dev/null

if [[ $? -ne 0 ]];
then
printf "Hashtable named blacklist does not exist. Creating it for you.\n"
ipset create blacklist hash:ip
fi

for badip in $list
do
ipset -q -A blacklist "$badip"
done

ipset -q save blacklist -f /etc/ipsets.conf &> /dev/null

printf "Cron blacklisting status OK - $(date)\n" >> /home/$USER/blacklist/status
