#!/usr/bin/env bash

# utility function for exiting
function die {
	echo "$@" >&2
	exit 1
}

SOURCE_DIR="/public"
BACKUPS_DIR="/mnt/lifebackup/loop/backups"
[[ -d "$BACKUPS_DIR" ]] || die "$0: backups dir not found"

MOST_RECENT_BACKUP=$(ls -1 "$BACKUPS_DIR" |grep -E '^[0-9]+$' |sort -n |tail -n 1)
if [[ -n "$MOST_RECENT_BACKUP" ]]; then
	MOST_RECENT_BACKUP_DIR="$BACKUPS_DIR/$MOST_RECENT_BACKUP"
	BACKUP_DIR="$BACKUPS_DIR/$((MOST_RECENT_BACKUP + 1))"
else
	# first backup!
	BACKUP_DIR="$BACKUPS_DIR/1"
fi
PARTIAL_DIR="$BACKUP_DIR.partial"
rm -fR "$PARTIAL_DIR"
mkdir "$PARTIAL_DIR"
date '+%Y-%m-%d %H:%M:%S' >"$PARTIAL_DIR/date_start.txt"
echo >>"$PARTIAL_DIR/backup.log" "$(date) - Backup started"
# TODO: run this command multiple times up to a maximum until it either:
# - takes less than a threshold amount of time
# - copies less tan a threshold number of files
# try to base timing on monotonically increasing clocks that are
# unaffected by date changes from ntp
rsync >>"$PARTIAL_DIR/backup.log" 2>&1 -avz --delete ${MOST_RECENT_BACKUP_DIR:+--link-dest="$MOST_RECENT_BACKUP_DIR/files"} "$SOURCE_DIR" "$PARTIAL_DIR/files"
echo >>"$PARTIAL_DIR/backup.log" "$(date) - Backup finished"
date '+%Y-%m-%d %H:%M:%S' >"$PARTIAL_DIR/date_end.txt"
touch "$PARTIAL_DIR/$(date)"
mv "$PARTIAL_DIR" "$BACKUP_DIR"
