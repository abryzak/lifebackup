#!/usr/bin/env bash

# utility function for exiting
function die {
	echo "$@" >&2
	exit 1
}

MNT_CIFS="/mnt/lifebackup/cifs"
MNT_LOOP="/mnt/lifebackup/loop"
CIFS_SERVICE="//192.168.1.100/Backup"

if [[ ! -f "$MNT_CIFS/backvol1" ]]; then
	#mount the cifs volume
	mount -t cifs "$CIFS_SERVICE"
fi
