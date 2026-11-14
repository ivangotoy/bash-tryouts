#!/usr/bin/env bash
# restic-backup/BACKUP-SCRIPT: a Google Drive mount that does not go away
# after the backup is reported as a failure, not as "UNMOUNTED".
. "$(dirname "$0")/lib.sh"

home="$WORK/home"
mkdir -p "$home/GoogleDriveBackup/ryzen-backup" "$WORK/log"
: > "$home/GoogleDriveBackup/ryzen-backup/config"

stub google-drive-ocamlfuse 'exit 0'
stub restic 'printf "%s\n" "$*" >> "$LOG/restic"'
stub fusermount3 'printf "%s\n" "$*" >> "$LOG/fusermount3"; [[ -z "$STUCK" ]] && rm -f "$LOG/mounted"; exit 0'
# mount stub: lists the drive while "$LOG/mounted" exists.
stub mount '[[ -e "$LOG/mounted" ]] && printf "gdfuse on %s type fuse.gdfuse (rw)\n" "$HOME/GoogleDriveBackup"; exit 0'

run_backup() {
	: > "$WORK/log/mounted"
	HOME="$home" LOG="$WORK/log" STUCK="$1" "$ZSH_BIN" "$REPO/restic-backup/BACKUP-SCRIPT" > "$WORK/out" 2>&1
}

run_backup ''
rc=$?
check "backup: exit 0 (got $rc)" test "$rc" -eq 0
check 'backup: restic backup ran' grep -q '^--cleanup-cache --compression max -q backup' "$WORK/log/restic"
check 'backup: drive unmounted' test ! -e "$WORK/log/mounted"

run_backup 1
rc=$?
check "drive stays mounted: exit 1 (got $rc)" test "$rc" -eq 1
check 'drive stays mounted: not reported as unmounted' test "$(grep -c 'DIR UNMOUNTED' "$WORK/out")" -eq 0

done_testing
