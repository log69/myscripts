#!/bin/bash
# info: opens a gpg protected file for viewing or editing with
#  the application that is the registered for the file type
#  and encrypts back its content after application exit
# usage: script file
# example: script file.txt.gpg
# depends: gnupg, stty, zenity, xdg-mime
# license: GPLv3+ <http://www.gnu.org/licenses/gpl.txt>
# Andras Horvath <mail@log69.com>


# print error message (to console or to GUI)
error(){
	# is command run from a console?
	CON=$(stty)
	if ! [ -z "$CON" ]; then
		# if so, then print message to console
		echo "$1"
	else
		# otherwise print it to GUI
		TITLE=$(basename $0)
		zenity --error --title "$TITLE" --text "$1"
	fi
}


# check if commands are available
if ! which gpg      &>/dev/null; then error "error: command gpg is missing";      exit 1; fi
if ! which stty     &>/dev/null; then error "error: command stty is missing";     exit 1; fi
if ! which zenity   &>/dev/null; then error "error: command zenity is missing";   exit 1; fi
if ! which xdg-mime &>/dev/null; then error "error: command xdg-mime is missing"; exit 1; fi

# store file name
FILE="$1"

# check if there are any parameters
if [ -z "$FILE" ]; then
	error "usage: script [encrypted file]"
	exit 1
fi

# check if file exists
if ! [ -f "$FILE" ]; then
	error "error: file doesn't exist"
	exit 1
fi


# temp file to store unencrypted file temporarily
TEMP=$(mktemp)
# temp file to store the stderr output of gpg
OUTP=$(mktemp)

# make sure to remove file even after abnormal program termination
trap "{ rm -f $TEMP $OUTP; exit 255; }" 0 1 2 3 5 15

# is command run from a console?
# use --no-tty option for gpg only if it's run from GUI
CON=$(stty)
if [ -z "$CON" ]; then
	# decrypt the file
	if ! /usr/bin/gpg --no-tty -v --decrypt "$FILE" 1>"$TEMP" 2>"$OUTP"; then
		# was it cancelled by user?
		if ! cat "$OUTP" | grep -q "cancelled by user"; then
			error "error: failure during decryption"
		fi
		# exit anyway
		exit 1
	fi
else
	# decrypt the file
	if ! /usr/bin/gpg -v --decrypt "$FILE" 1>"$TEMP" 2>"$OUTP"; then
		# was it cancelled by user?
		if ! cat "$OUTP" | grep -q "cancelled by user"; then
			error "error: failure during decryption"
		fi
		# exit anyway
		exit 1
	fi
fi

# grep key id from gpg output
KEYID=$(cat "$OUTP" | grep "public key is" | grep -oE "[^ ]+$")

# is it a public key encrypted file?
# if symmetric encryption, then failure
if [ -z "$KEYID" ]; then
	error "error: not a public key encrypted file"
	exit 1
fi

# get the file name without the last (.gpg) extension
F2=$(echo "$FILE" | grep -oE "^.*\." | head -c-2)
F3=$(basename "$F2")
# determine the type of file
T2=$(mktemp XXXXXX."$F3")
TYPE=$(xdg-mime query filetype "$T2")
rm -f "$T2"
# determine the associated app (returns a .desktop file)
APP=$(xdg-mime query default "$TYPE")
# determine the real name of the app
BIN=$(grep -m1 -i "^exec=" /usr/share/applications/"$APP" | grep -i "^exec" | grep -oE "^[^ ]+" | tail -c+6)


# open file with app and wait for the process to terminate
"$BIN" "$TEMP" &>/dev/null && wait
# encrypt back its content
cat "$TEMP" | /usr/bin/gpg -e -r "$KEYID" 1>"$FILE"
chmod 600 "$FILE"
# delete unencrypted data
rm -f "$TEMP" "$OUTP"

# sync to make sure the deletion is committed
sync

exit
