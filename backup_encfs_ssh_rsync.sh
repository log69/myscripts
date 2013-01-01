#!/bin/bash
# info: creates a backup of local directory to a remote machine
#   through an SSH protocol using Rsync for copy and EncFS for encryption
# depends: fuse, encfs, ssh, rsync
# remarks:
#   - user must be part of group fuse
#   - remote directory must be compliant with the Rsync format
#   - exclude directories must be relative to local directory
# usage: command LOCAL_DIR REMOTE_DIR [DIR1_TO_EXCLUDE DIR2_TO_EXCLUDE ...]
# example: backup_encfs_ssh_rsync.sh /home/user user@server.com:2222/home/user/backup .bashrc pictures/private

# check if necessary commands installed?
if ! which encfs &>/dev/null; then echo "error: encfs command missing"; exit 1; fi
if ! which ssh   &>/dev/null; then echo "error: ssh command missing";   exit 1; fi
if ! which rsync &>/dev/null; then echo "error: rsync command missing"; exit 1; fi

# print help if no arguments
if [ $# -lt 1 ]; then echo "usage: command LOCAL_DIR REMOTE_DIR [DIR1_TO_EXCLUDE DIR2_TO_EXCLUDE ...]"; exit 0; fi

# check to have the minimum arguments required
if [ $# -lt 2 ]; then echo "error: too few arguments"; exit 1; fi

# is user part of group fuse?
if ! grep fuse /etc/group | grep -q "$USER"; then echo "error: user must be in group fuse"; exit 1; fi

# store argument values
BACKUP_DIR=$(readlink -f $1)
REMOTE_DIR="$2"
EXCLUDE_LIST=""

# get password
echo -n "enter password: "
read -s PASS
echo


# any dirs to exclude specified (more than 2 arguments)?
if [ $# -gt 2 ]
then
	# read args from 3rd only and store dir name with --exclude option of rsync
	EXCLUDE_LIST=$(echo $@ | tr -s " " "\n" | tail -n+3 | while read DIR; do
		N=$(encfsctl encode --extpass "echo $PASS" "$BACKUP_DIR" "$DIR")
		echo -n " --exclude=\"$N\""
	done)
fi

# create dir for encrypted view
ENCRYPTED_DIR=$(mktemp -d)
trap "{ fusermount -u "$ENCRYPTED_DIR" &>/dev/null; rmdir "$ENCRYPTED_DIR" &>/dev/null; }" 0 1 2 3 5 15

# mount encfs in reverse mode to see files encrypted
encfs --reverse --standard --extpass "echo $PASS" "$BACKUP_DIR" "$ENCRYPTED_DIR" || exit 1

# sync datas and encfs xml option file to remote machine
# xml option file must stand first to not delete it
rsync -avz --progress "$BACKUP_DIR"/.encfs6.xml --delete --delete-excluded $EXCLUDE_LIST "$ENCRYPTED_DIR"/ "$REMOTE_DIR"/

# unmount dir
fusermount -u "$ENCRYPTED_DIR" &>/dev/null
rmdir "$ENCRYPTED_DIR" &>/dev/null
