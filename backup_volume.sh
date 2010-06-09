#!/usr/bin/env bash

# utility function for exiting
function die {
	echo "$@" >&2
	exit 1
}

MNT_BASE="/mnt/lifebackup"
MNT_CIFS="$MNT_BASE/cifs"
MNT_LOOP="$MNT_BASE/loop"
CIFS_SERVICE="//192.168.1.100/Backup"

function mount_backup_volumes {
	mount |grep -F -q " on $MNT_LOOP " && return
	if [[ ! -f "$MNT_CIFS/backvol1" ]]; then
		# mount the cifs volume
		mount -t cifs "$CIFS_SERVICE" "$MNT_CIFS" -o guest || die "unable to mount cifs"
	fi
	for VOLUME_FILE in "$MNT_CIFS/backvol"*; do
		losetup -a |grep -q "($VOLUME_FILE)\$" && continue
		losetup -f "$VOLUME_FILE" || die "unable to mount loop device $VOLUME_FILE"
	done
	vgscan >/dev/null || die "vgscan failed"
	lvchange -ay lifebackup || die "unable to activate lifebackup volume"
	mount -t ext3 /dev/lifebackup/lifebackup "$MNT_LOOP"
}

function umount_backup_volumes {
	umount "$MNT_LOOP"
	lvchange -an lifebackup
	for VOLUME_FILE in "$MNT_CIFS/backvol"*; do
		LOOP_DEVICE=$(losetup -a |grep "($VOLUME_FILE)\$") || continue
		LOOP_DEVICE=${LOOP_DEVICE%%:*}
		losetup -d "$LOOP_DEVICE"
	done
	vgscan >/dev/null
	umount "$MNT_CIFS"
	return 0
}

case "$1" in
mount)	mount_backup_volumes
	;;
umount)	umount_backup_volumes
	;;
*)	echo >&2 "unknown action: $1"
	exit 2
	;;
esac
exit 0
