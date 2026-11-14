> ⚠️ **Mirror.** Primary repository: [git.digtvbg.com](https://git.digtvbg.com/ivangotoy/bash-tryouts/)
> Development, issues, and PRs happen there. The GitHub repo is read-only.

# bash-tryouts

POWERED BY ETHIOPIA YIRGACHEFFE SPECIALTY COFFEE SCA 84 - PROCESS HONEY HEIRLOOM

Results oriented mindset. Tooling and skills just help for delivery of results.

Old demo scripts, kept for reference. Read a script before running it: most
of them touch real system state (firewall, VPN, router firmware, backups)
and several need root.

Some tooling and scripting tricks someone might find a bit awkward for
the typical bash scripting standards:

- rg (ripgrep) - I feel it like a better (a tad faster) rusty grep.
- zsh - a shell which I find splendid; scripts find it with `#!/usr/bin/env zsh`
- printf instead of echo for a change. \n :)
- busybox shuf - a nice shuffling utility but its busybox variant
- play from the sox package
- wget as a curl alternative
- adb - the Android Debug Bridge.
- for evaluation [[  ]] instead of [  ] (except in the busybox ash script)
- for substitution use $() instead of backticking ``
- restic - backups done not left but righty-ish
- msmtp - at least a maintained utility for emailing
- ipset - nice utility for you know... better iptables management

## Scripts

| Path | Shell | Runs on | What it does |
| --- | --- | --- | --- |
| cron/alerter.sh | zsh | server, cron | mails (sendmail/msmtp) when nginx, php-fpm, mariadb or tvheadend is not running |
| cron/blacklist.sh | zsh | server, root cron | bans IPs that probe nginx for exploits, via ipset + iptables |
| cron/UPDATE-WAF-CORERULESETS-CRONJOB | zsh | server, root cron | git pulls the ModSecurity Core Rule Set and reloads nginx |
| cron/navidrome-update-openwrt-ash | busybox ash | OpenWrt router, cron | updates Navidrome from the latest GitHub release (linux_$ARCH asset) |
| cron/PROTIP-DNS-ADBLOCK-ADVICE.txt | - | - | dnscrypt-proxy 2 as an ad blocker |
| macgen/macgen | zsh | desktop | all 16.7M MACs for a prefix, shuffled, optionally split |
| nordvpn/BG-WG-16-NORDVPN, ES-WG-16-NORDVPN | zsh | desktop | 16 least loaded NordVPN WireGuard servers in Bulgaria / Spain |
| nordvpn/NORDVPN-SERVERS | zsh | desktop | 20 least loaded WireGuard servers for any country, picked from a list |
| nordvpn/SERVER-SWITCHER | zsh | desktop, root | moves wg-quick@bg to the least loaded Bulgarian server |
| nordvpn/bg.conf | - | - | template WireGuard config for SERVER-SWITCHER |
| openwrt/ruter-upgrade | zsh | build machine | builds x86 OpenWrt and sysupgrades the router over ssh |
| restic-backup/BACKUP-SCRIPT | zsh | desktop | restic backup to a google-drive-ocamlfuse mount |
| roborock/* | zsh / sh | desktop / vacuum | music and radio on a rooted Roborock, see roborock/Readme.txt |
| system/IP-INFO | zsh | any | LAN and public IP |
| system/bulk-apk-installer.sh | zsh | desktop | adb install of every apk in the current directory tree |
| system/hugepages.sh | bash | any | transparent hugepages count and size |
| system/jukebox-pc.sh | bash | desktop | plays the audio of a YouTube video (yt-dlp, paplay) |
| system/nvme-disks-temperatures | bash | any, root | NVMe temperatures (nvme-cli) |
| system/odroid-cpu-temp.sh | bash | ODROID N2 | CPU cluster temperatures |
| system/stats.sh | zsh | any | memory, disk and load summary |
| tools/lint.sh | bash | any | syntax check and shellcheck for the scripts, see Linting and testing |
| tests/run.sh | bash | any | regression tests with stub commands, see Linting and testing |

Log size limits (each script trims its own log after writing, keeping the
newest lines; no logrotate needed):

- cron/blacklist.sh: ~/blacklist/status keeps its last 1000 lines.
- cron/UPDATE-WAF-CORERULESETS-CRONJOB: /var/log/coreruleset-updates.log keeps its last 1000 lines.

## Linting and testing

    tools/lint.sh             # every tracked script
    tools/lint.sh cron/*.sh   # only these files
    tests/run.sh              # regression tests

It picks the check from each file's shebang: `zsh -n`, `bash -n`, `sh -n`,
and `busybox ash -n` (or `bash --posix -n` when busybox is missing) for
the ash script. When shellcheck is installed (or `SHELLCHECK` points to
it) the bash, sh and ash scripts are also run through it; shellcheck has
no zsh support. Exit status 1 means at least one check failed. There is
no CI; run both before committing.

tests/run.sh runs every tests/test-*.sh. The tests never touch the network
or the system: each one runs a script with a PATH that holds only stub
commands (curl, ssh, ipset, systemctl, ... answering from fixtures) and
symlinks to local tools (coreutils, shells, grep, sed, awk, jq), and keeps
its files in a scratch directory under `$TMPDIR` (or `~/.cache` when TMPDIR
is unset). Scripts with hard coded system paths are tested on a copy with
only those paths rewritten. The root-only scripts are run as root of an
unprivileged user namespace (`unshare -r`); without one those tests are
skipped and say so.

## nordvpn: supplying the WireGuard private key

nordvpn/bg.conf ships with the placeholder
`REPLACE_WITH_YOUR_WIREGUARD_PRIVATE_KEY`. Never commit a real key.
Install a private copy and edit only that copy:

    sudo install -m 600 nordvpn/bg.conf /etc/wireguard/bg.conf
    sudoedit /etc/wireguard/bg.conf

The key is your own NordLynx (WireGuard) private key. Two common ways to get
it: connect once with the official nordvpn Linux app using the NordLynx
technology and read it with `sudo wg show nordlynx private-key`, or ask the
NordVPN API (`/v1/users/services/credentials`, field `nordlynx_private_key`)
with an access token from your NordVPN account. Then
`systemctl start wg-quick@bg`.
