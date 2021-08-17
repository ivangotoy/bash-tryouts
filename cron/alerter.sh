#!/usr/bin/env zsh
#
# Ivan Angelov ivangotoy@gmail.com
# https://digtvbg.com/
#
# Very basic crontab suitable bash script that will send an email when:
#
# - nginx and/or mariadb and/or tvheadend and/or php-fpm7.4 processes are not running.
# 
# Can be used as a template for monitoring various processes on servers 
#
# msmtp should be configured for sending email on the system.
#

PATH="/home/$USER/.local/bin:/usr/bin:/usr/local/bin:/usr/sbin:/sbin:/usr/local/bin:/usr/bin:/bin:/usr/local/games:/usr/games:/home/$USER/alerter"
PROCESS1="nginx"
PROCESS2="php-fpm7.4"
PROCESS3="mariadbd"
PROCESS4="tvheadend"
MAILER="$(which sendmail)"
SENDER="username@email.xxx"
RECEPIENT="$SENDER"
SUBJECT1=""$PROCESS1" NOT RUNNING :("
SUBJECT2=""$PROCESS2" NOT RUNNING :("
SUBJECT3=""$PROCESS3" NOT RUNNING :("
SUBJECT4=""$PROCESS4" NOT RUNNING :("
NEGATIVE1="To:$RECEPIENT\nFrom:$SENDER\nSubject:$SUBJECT1\n$PROCESS1 is not running!!! Please, check digtvbg.com\nRegards,\nDigtvbg.com Alerter Cron\n"
NEGATIVE2="To:$RECEPIENT\nFrom:$SENDER\nSubject:$SUBJECT2\n$PROCESS2 is not running!!! Please, check digtvbg.com\nRegards,\nDigtvbg.com Alerter Cron\n"
NEGATIVE3="To:$RECEPIENT\nFrom:$SENDER\nSubject:$SUBJECT3\n$PROCESS3 is not running!!! Please, check digtvbg.com\nRegards,\nDigtvbg.com Alerter Cron\n"
NEGATIVE4="To:$RECEPIENT\nFrom:$SENDER\nSubject:$SUBJECT4\n$PROCESS4 is not running!!! Please, check digtvbg.com\nRegards,\nDigtvbg.com Alerter Cron\n"
RETCODE1="$(pidof $PROCESS1 >/dev/null 2>&1; echo $? )"
RETCODE2="$(pidof $PROCESS2 >/dev/null 2>&1; echo $? )"
RETCODE3="$(pidof $PROCESS3 >/dev/null 2>&1; echo $? )"
RETCODE4="$(pidof $PROCESS4 >/dev/null 2>&1; echo $? )"
if [ "$RETCODE1" -eq 1 ];
then
printf "$NEGATIVE1" | "$MAILER" -t
fi
if [ "$RETCODE2" -eq 1 ];
then
printf "$NEGATIVE2" | "$MAILER" -t
fi
if [ "$RETCODE3" -eq 1 ];
then
printf "$NEGATIVE3" | "$MAILER" -t
fi
if [ "$RETCODE4" -eq 1 ];
then
printf "$NEGATIVE4" | "$MAILER" -t
fi
