#!/bin/sh
# beerware license, written by Aldis Berjoza (aldis@bsdroot.lv)

VERSION=1.1

s2time() {
	# convert seconds to human readable time
	xtime=$*

	years=`expr $xtime / 31536000`
	xtime=`expr $xtime % 31536000`
	[ ${years:-0} -gt 0 ] && years="${years}y" || years=""

	months=`expr $xtime / 2592000`
	xtime=`expr $xtime % 2592000`
	[ ${months:-0} -gt 0 ] && months="${months}m" || months=""

	days=`expr $xtime / 86400`
	xtime=`expr $xtime % 86400`
	[ ${days:-0} -gt 0 ] && days="${days}d" || days=""

	hours=`expr $xtime / 3600`
	xtime=`expr $xtime % 3600`
	[ ${hours:-0} -gt 0 ] && hours="${hours}h" || hours=""

	minutes=`expr $xtime / 60`
	[ ${minutes:-0} -gt 0 ] && minutes="${minutes}M" || minutes=""

	seconds=`expr $xtime % 60`
	[ ${seconds:-0} -gt 0 ] && seconds="${seconds}s" || seconds=""

	echo "${years}${months}${days}${hours}${minutes}${seconds}"
}

time2s() {
	# convert human readable time to seconds
	echo "$1" | sed -e 's/y/*31536000+/' -e 's/m/*2592000+/' -e 's/w/*604800+/' -e 's/d/*86400+/' -e 's/h/*3600+/' -e 's/M/*60+/' -e 's/s//' -e 's/\+$//' | bc -l
}

help() {
	cat << EOF
${0##./} v${VERSION} by Aldis Berjoza

Syntax:
${0##./} [generic options] [[-a ttl] [-r|-R] z/fs1 ...]

GENERIC OPTIONS:
-d       = delete old snapshots
-v       = verbose output

OPTIONS:
-a ttl   = set how long snapshot should be kept
-r       = recursive snapshots
-R       = Not recursive snapshots

NOTES:
  ttl can be specified as number in which case it is treated as value in
seconds, or it can be specified as numbers and modifiers [For example 1y6m
- if you want to keep snapshot for 1 year and 6 months].

  Valid modifiers: y - years (365 days / year), m - months (30 days / month),
w - weeks, d - days, h - hours, M - minutes, s - seconds (can be omitted)
  Modifiers must be in order mentioned above. You don't need to specify all
modifiers. Just specifie modifiers that you need (for example '1y', '3w',
'6m10d')

  ttl can also be specified as label, in which case snapshot won't be deleted
(ever)

  when you use -r option, this means that all zfs filesystems specified on
command line after will make recursive snapshots. To cansel recursive
snapshots use -R. For example:
  ${0##./} zpool/zfs1 -r zpool/zfs3 zpool/zfs4 -R zpool/zfs4 zpool/zfs5
  * zpool/zfs3 zpool/zfs4             - will be recrusive
  * zpool/zfs1 zpool/zfs4 zpool/zfs5  - won't be recursive

Generic options must be specified before anything else
EOF
	exit
}

[ $# = 0 ] && help
[ "$1" = '-h' -o $1 = "--help" ] && help

tfrmt="%Y-%m-%d_%T"
htime_pattern='(([0-9])+y)?(([0-9])+m)?(([0-9])+w)?(([0-9])+d)?(([0-9])+h)?(([0-9])+M)?(([0-9])+(s)?)?'
date_pattern='20[0-9]{2}-[01][0-9]-[0-3][0-9]_[0-2][0-9]:[0-6][0-9]:[0-6][0-9]'
age=`s2time 2592000`	# default max snapshot age in seconds (30 days)
delete_snapshots=0
verbose=0

while [ "$1" = '-d' -o "$1" = '-v' ]; do
	[ "$1" = "-d" ] && delete_snapshots=1 && shift
	[ "$1" = "-v" ] && verbose=1 && shift
done

ntime=`date "+$tfrmt"`
while [ "$1" ]; do
	while [ "$1" = '-r' -o "$1" = '-R' -o "$1" = '-a' ]; do
		[ "$1" = '-r' ] && zopt='-r' && shift
		[ "$1" = '-R' ] && zopt='' && shift
		[ "$1" = '-a' ] && age="$2" && shift 2 && echo "$age" | grep -E -e "^[0-9]+$" 2> /dev/null > /dev/null && age=`s2time $age`
	done

	if [ $1 ]; then
		[ $verbose -eq 1 ] && echo -n "zfs snapshot $zopt $1@${ntime}--${age}	... "
		zfs snapshot $zopt "$1@${ntime}--${age}" 1> /dev/stderr > /dev/stderr \
			&& { [ $verbose -eq 1 ] && echo 'DONE'; } \
			|| { [ $verbose -eq 1 ] && echo 'FAIL'; }
		shift
	fi
done

if [ "$delete_snapshots" -eq 1 ]; then
	for i in `zfs list -H -t snapshot | awk '{print $1}' | grep -E -e "^.*@${date_pattern}--${htime_pattern}$"`; do
		dtime=$(time2s `echo $i | sed -E -e "s/.*@${date_pattern}--//"`)
		if [ `expr $(date +%s) - $dtime` -gt $(date -j -f "$tfrmt" $(echo "$i" | sed -e "s/^.*@//" -E -e "s/--${htime_pattern}$//") +%s) ]; then
			[ $verbose -eq 1 ] && echo -n "zfs destroy $i	... "
			zfs destroy "$i" 2> /dev/stderr > /dev/stderr \
				&& { [ $verbose -eq 1 ] && echo 'DONE'; } \
				|| { [ $verbose -eq 1 ] && echo 'FAIL'; }

		fi
	done
fi

exit 0
