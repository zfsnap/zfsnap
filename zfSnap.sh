#!/bin/sh
# beerware license, written by Aldis Berjoza (aldis@bsdroot.lv)

age=2592000	# max snapshot age in seconds

tfrmt="%Y.%m.%d_%T"

[ "$1" = "-r" ] && { zopt=-r; shift; } # if arg1 = -r them make recursive snapshots

ntime=`date +$tfrmt`
for i in $*; do 
	zfs snapshot $zopt $i@$ntime
done

dtime=`date +%s-$age | bc -l`
for i in `zfs list -H -t snapshot | awk '{print $1}' | grep -E -e '^.*@20[0-9]{2}\.[01][0-9]\.[0-3][0-9]_[0-2][0-9]:[0-6][0-9]:[0-6][0-9]$'`; do
	[ $dtime -gt $(date -j -f $tfrmt $(echo $i | sed -e 's/^.*@//') +%s) ] && zfs destroy $i
done

exit 0
