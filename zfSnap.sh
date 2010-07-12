#!/bin/sh
# beerware license, written by Aldis Berjoza (aldis@bsdroot.lv)

# if arg1 is -a. snapshot max age will be set to arg2
# all next args are zfs filesystems
# before zfs filesystem you can pass optional arg -r, to specify
#   that zfs should create recursive snapshots for given filesystem

# Syntax:
# zfSnap.sh [-a MaxSnapshotAgeInSeconds] [-r] z/fs1 [[[-r] z/fs2] ...]

age=2592000	# default max snapshot age in seconds
[ $1 = '-a' ] && { age=$2; shift 2; }

tfrmt="%Y-%m-%d_%T"

ntime=`date +$tfrmt`
while [ $1 ]; do
	[ $1 = '-r' ] && { zopt=$1; shift 2; } || zopt=''
	zfs snapshot $zopt $1@$ntime
	shift
done

dtime=`date +%s-$age | bc -l`
for i in `zfs list -H -t snapshot | awk '{print $1}' | grep -E -e '^.*@20[0-9]{2}-[01][0-9]-[0-3][0-9]_[0-2][0-9]:[0-6][0-9]:[0-6][0-9]$'`; do
	[ $dtime -gt $(date -j -f $tfrmt $(echo $i | sed -e 's/^.*@//') +%s) ] && zfs destroy $i
done

exit 0
