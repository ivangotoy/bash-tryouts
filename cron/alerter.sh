#!/usr/bin/env zsh
#
# Ivan Angelov ivangotoy@gmail.com
# https://digtvbg.com/
#
# Very basic crontab suitable zsh script that sends one email per process
# that is not running. Default list: nginx, php-fpm, mariadbd, tvheadend.
#
# Can be used as a template for monitoring various processes on servers.
#
# msmtp (or any sendmail compatible MTA) should be configured on the system;
# with msmtp install the msmtp-mta package or link msmtp as sendmail.

PATH="$HOME/.local/bin:/usr/local/bin:/usr/bin:/bin:/usr/local/sbin:/usr/sbin:/sbin:/usr/local/games:/usr/games:$HOME/alerter"

# php-fpm: by default any php-fpm version counts (pgrep -f '^php-fpm' matches
# "php-fpm: master process" of every version). Set PHP_FPM to watch one exact
# process name instead, e.g. PHP_FPM=php-fpm8.2 alerter.sh
php_fpm="${PHP_FPM:-php-fpm}"
processes=(nginx "$php_fpm" mariadbd tvheadend)
sender="username@email.xxx"
recipient="$sender"
site="digtvbg.com"

mailer="$(command -v sendmail)"
if [[ -z "$mailer" ]]; then
	printf 'sendmail not found in PATH, cannot send alerts.\n' >&2
	exit 1
fi

for process in $processes; do
	if [[ "$process" == php-fpm && -z "$PHP_FPM" ]]; then
		pgrep -f '^php-fpm' >/dev/null 2>&1 && continue
	else
		pidof "$process" >/dev/null 2>&1 && continue
	fi
	printf 'To: %s\nFrom: %s\nSubject: %s NOT RUNNING :(\n\n%s is not running!!! Please, check %s\nRegards,\n%s Alerter Cron\n' \
		"$recipient" "$sender" "$process" "$process" "$site" "Digtvbg.com" | "$mailer" -t
done
