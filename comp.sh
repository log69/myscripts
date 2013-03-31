#!/bin/bash
# info: compress file or directory

FILE="$1"
FNAME=`basename "$FILE"`

if [ -z "$FILE" ]; then echo "usage: command [dir|file]"; exit 1; fi


if [ -d "$FILE" ];
then

	SIZE=`du -sb "$FILE" | cut -f1`
	tar -cf - "$FILE" 2>/dev/null | pv -s "$SIZE" | lbzip2 > "$FNAME".tar.bz2

else

	pv "$FILE" | lbzip2 > "$FNAME".bz2

fi
