#!/bin/sh
# create readonly snapshot of root dir
# and delete oldest ones

# snapshot dir
DIR="/snapshot"

# number of snapshots to leave for daily
ND="7"
# for monthly
NM="1"

# create daily snapshot
mkdir -p "$DIR"
btrfs sub snap -r / "$DIR"/`date +%Y%m%d%H%M%S`_daily

# create monthly too if it doesn't exist
if ! ls -1d "$DIR"/`date +%Y%m`*_monthly &>/dev/null; then
   btrfs sub snap -r / "$DIR"/`date +%Y%m%d%H%M%S`_monthly
fi

# delete oldest ones for daily (n+1 for tail)
ls -1rd "$DIR"/*_daily 2>/dev/null | \
   tail -n+$(($ND+1)) | while read FF; do \
      btrfs sub del "$FF"; done

# delete for monthly too
ls -1rd "$DIR"/*_monthly 2>/dev/null | \
   tail -n+$(($NM+1)) | while read FF; do \
      btrfs sub del "$FF"; done

