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
myip="127.0.0.1|192.168.1.1|192.168.1.222|192.168.1.70"
list="$(rg "jndi|system.php|actuator|kerbynet|RadEditorProvider|telerikwebui|Telerik.Web.UI|phpMyAdmin|content-post.php|mide.php|phpunit|HEADER.md|/owa/auth/logon.aspx|main.installer.php|\?author=[0-9]|wp-login.php|logon|getuser|execute|passwd|Nikto|/\.env |nuclei|union|UNION|sql|conf|/[(w|x)]*shell|cmd|Admin|admin|cfg|boaform" "$log" | rg -v "$myip|DuckDuckBot|Adsbot|Googlebot|YandexBot|bingbot|SemrushBot|PetalBot" | cut -d ' ' -f 1,9 | rg '301|302|400|403|404|499' | cut -d ' ' -f 1 | sort --parallel=4 -n | uniq -i)"

if [[ "$EUID" -ne 0 ]]; then
printf "This script must be run as root! sudo $0 \n"
exit 1
fi

if [[ ! -d ~/blacklist ]];
then
mkdir -p ~/blacklist
touch ~/blacklist/status
fi

if [[ ! -f "$log" ]];
then
printf "$log not found! If you have one - provide proper location in this script and retry.\n"
exit 1
fi

ipset -q list blacklist &> /dev/null

if [[ $? -ne 0 ]];
then
printf "Hashtable named blacklist does not exist. Creating it for you.\n"
ipset create blacklist hash:ip
fi

iptables-save | rg blacklist &> /dev/null

if [[ $? -ne 0 ]];
then
  iptables -I INPUT -m set --match-set blacklist src -j DROP
fi

printf "create blacklist hash:ip family inet hashsize 4096 maxelem 65536 bucketsize 12 initval 0x6084fd11\n$list\n" | sed '1! s/^/add blacklist /g' > ~/blacklist/ipsets.conf
ipset -q flush blacklist
ipset -q restore -! < ~/blacklist/ipsets.conf &> /dev/null

printf "Cron blacklisting status OK - $(date)\n" >> ~/blacklist/status

exit 0
