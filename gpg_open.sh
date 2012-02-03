#!/bin/bash
# info: opens a gpg protected file for viewing or editing with
#  the application that is the registered for the file type
#  and encrypts back its content after application exit
# usage: script file
# example: script file.txt.gpg
# depends: gnupg
# license: GPLv3+ <http://www.gnu.org/licenses/gpl.txt>
# Andras Horvath <mail@log69.com>


# store file name
FILE="$1"

# check if there are any parameters
if [ -z "$FILE" ]; then
	echo "usage: script [encrypted file]"
	exit 1
fi

# check if file exists
if ! [ -f "$FILE" ]; then
	echo "error: file doesn't exist"
	exit 1
fi


# file to store unencrypted file temporarily
TEMP=$(mktemp /dev/shm/tmp.XXXXXX)
OUTP=$(mktemp /dev/shm/tmp.XXXXXX)

# make sure to remove file even after abnormal program termination
trap "{ rm -f $TEMP $OUTP; exit 255; }" 0 1 2 3 5 15

# decrypt the file
if ! /usr/bin/gpg -v --decrypt "$FILE" 1>"$TEMP" 2>"$OUTP"; then
	echo "error: failure during decryption"
	cat "$OUTP"
	exit 1
fi

# grep key id from gpg output
KEYID=$(cat "$OUTP" | grep "public key is" | grep -oE "[^ ]+$")

# is it a public key encrypted file?
# if symmetric encryption, then failure
if [ -z "$KEYID" ]; then
	echo "error: not a public key encrypted file"
	exit 1
fi

# open file and wait for the process to terminate
echo $(xdg-open $TEMP) &>/dev/null && wait
# encrypt back its content
cat "$TEMP" | /usr/bin/gpg -e -r "$KEYID" 1>"$FILE"
chmod 600 "$FILE"
# delete unencrypted data
rm -f "$TEMP" "$OUTP"

# sync to make sure the deletion is committed
sync

exit
