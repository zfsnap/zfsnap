#!/bin/sh

# "THE BEER-WARE LICENSE":
# <graudeejs@gmail.com> wrote this file. As long as you retain this notice you
# can do whatever you want with this stuff. If we meet some day, and you think
# this stuff is worth it, you can buy me a beer in return. Aldis Berjoza

# wiki:             https://github.com/graudeejs/zfSnap/wiki
# repository:       https://github.com/graudeejs/zfSnap
# Bug tracking:     https://github.com/graudeejs/zfSnap/issues
# feedback email:   graudeejs@gmail.com

readonly VERSION=1.10.4

OS=`uname`
case $OS in
'Darwin')
	readonly zfs_cmd=/usr/sbin/zfs
	readonly zpool_cmd=/usr/sbin/zpool
	;;
*)
	readonly zfs_cmd=/sbin/zfs
	readonly zpool_cmd=/sbin/zpool
	;;
esac

case $OS in
'Darwin' | 'FreeBSD')
	ESED='sed -E'
	;;
'SunOS' | 'Linux')
	ESED='sed -r'
	;;
*)
	echo "ERR: Your OS isn't supported" > /dev/stderr
	exit 1
	;;
esac

s2time() {
	# convert seconds to human readable time
	xtime=$1

	years=$(($xtime / 31536000))
	xtime=$(($xtime % 31536000))
	[ ${years:-0} -gt 0 ] && years="${years}y" || years=""

	months=$(($xtime / 2592000))
	xtime=$(($xtime % 2592000))
	[ ${months:-0} -gt 0 ] && months="${months}m" || months=""

	days=$(($xtime / 86400))
	xtime=$(($xtime % 86400))
	[ ${days:-0} -gt 0 ] && days="${days}d" || days=""

	hours=$(($xtime / 3600))
	xtime=$(($xtime % 3600))
	[ ${hours:-0} -gt 0 ] && hours="${hours}h" || hours=""

	minutes=$(($xtime / 60))
	[ ${minutes:-0} -gt 0 ] && minutes="${minutes}M" || minutes=""

	seconds=$(($xtime % 60))
	[ ${seconds:-0} -gt 0 ] && seconds="${seconds}s" || seconds=""

	echo "${years}${months}${days}${hours}${minutes}${seconds}"
}

time2s() {
	# convert human readable time to seconds
	echo "$1" | sed -e 's/y/*31536000+/g; s/m/*2592000+/g; s/w/*604800+/g; s/d/*86400+/g; s/h/*3600+/g; s/M/*60+/g; s/s//g; s/\+$//' | bc -l
}

date2timestamp() {
	date_normal="`echo $1 | $ESED -e 's/\./:/g; s/(20[0-9][0-9]-[01][0-9]-[0-3][0-9])_([0-2][0-9]:[0-5][0-9]:[0-5][0-9])/\1 \2/'`"

	case $OS in
	'FreeBSD')
		date -j -f '%Y-%m-%d %H:%M:%S' "$date_normal" '+%s'
		;;
	*)
		date --date "$date_normal" '+%s'
		;;
	esac
}

help() {
	cat << EOF
${0##*/} v${VERSION} by Aldis Berjoza

Syntax:
${0##*/} [ generic options ] [ options ] zpool/filesystem ...

GENERIC OPTIONS:
  -d           = Delete old snapshots
  -e           = Return number of failed actions as exit code.
  -F age       = Force delete all snapshots exceeding age
  -n           = Only show actions that would be performed
  -s           = Don't do anything on pools running resilver
  -S           = Don't do anything on pools running scrub
  -v           = Verbose output
  -z           = Force new snapshots to have 00 seconds!
  -zpool28fix  = Workaround for zpool v28 zfs destroy -r bug

OPTIONS:
  -a ttl       = Set how long snapshot should be kept
  -D pool/fs   = Delete all zfSnap snapshots of specific pool/fs (ignore ttl)
  -p prefix    = Use prefix for snapshots after this switch
  -P           = Don't use prefix for snapshots after this switch
  -r           = Create recursive snapshots for all zfs file systems that
                 fallow this switch
  -R           = Create non-recursive snapshots for all zfs file systems that
                 fallow this switch

LINKS:
  wiki:             https://github.com/graudeejs/zfSnap/wiki
  repository:       https://github.com/graudeejs/zfSnap
  Bug tracking:     https://github.com/graudeejs/zfSnap/issues
  feedback email:   graudeejs@gmail.com

EOF
	exit 0
}

rm_zfs_snapshot() {
	if [ $zpool28fix -eq 1 -a "$1" = '-r' ]; then
		# get rid of '-r' parameter
		rm_zfs_snapshot $2
		return
	fi

	if [ "$1" = '-r' ]; then
		skip_pool $2 || return 1
	else
		skip_pool $1 || return 1
	fi

	zfs_destroy="$zfs_cmd destroy $*"

	# hardening: make really, really sure we are deleting snapshot
	if echo $i | grep -q -e '@'; then
		if [ $dry_run -eq 0 ]; then
			if $zfs_destroy > /dev/stderr; then
				[ $verbose -ne 0 ] && echo "$zfs_destroy	... DONE"
			else
				[ $verbose -ne 0 ] && echo "$zfs_destroy	... FAIL"
				[ $count_failures -ne 0 ] && failures=$(($failures + 1))
			fi
		else
			echo "$zfs_destroy"
		fi
	else
		echo "ERR: trying to delete zfs pool or filesystem? WTF?" > /dev/stderr
		echo "  This is bug, we definitely don't want that." > /dev/stderr
		echo "  Please report it to zfsnap@bsdroot.lv" > /dev/stderr
		echo "  Don't panic, nothing was deleted :)" > /dev/stderr
		[ $count_failures -ne 0 -a $failures > 0 ] && exit $failures
		exit 1
	fi
}

skip_pool() {
	# more like skip pool???
	if [ $scrub_skip -ne 0 ]; then
		for i in $scrub_pools; do
			if [ `echo $1 | sed -e 's#/.*$##; s/@.*//'` = $i ]; then
				[ $verbose -ne 0 ] && echo "NOTE: No action will be performed on '$1'. Scrub is running on pool." > /dev/stderr
				return 1
			fi
		done
	fi
	if [ $resilver_skip -ne 0 ]; then
		for i in $resilver_pools; do
			if [ `echo $1 | sed -e 's#/.*$##; s/@.*//'` = $i ]; then
				[ $verbose -ne 0 ] && echo "NOTE: No action will be performed on '$1'. Resilver is running on pool." > /dev/stderr
				return 1
			fi
		done
	fi
	return 0
}


[ $# = 0 ] && help
[ "$1" = '-h' -o $1 = "--help" ] && help

ttl='1m'	# default snapshot ttl
force_delete_snapshots_age=-1	# Delete snapshots older than x seconds. -1 means NO
delete_snapshots=0				# Delete old snapshots? 0 = NO
delete_specific_snapshots=0		# Delete specific snapshots? 0 = NO
verbose=0						# Verbose output? 0 = NO
dry_run=0						# Dry run? 0 = NO
prefx=""						# Default prefix
prefxes=""						# List of prefixes
delete_specific_fs_snapshots=""	# List of specific snapshots to delete
delete_specific_fs_snapshots_recursively=""	# List of specific snapshots to delete recursively
zero_seconds=0					# Should new snapshots always have 00 seconds? 0 = NO
scrub_pools=""					# List of pools that are in precess of scrubing
resilver_pools=""				# List of pools that are in process of resilvering
pools=""						# List of pools
get_pools=0						# Should I get list of pools? 0 = NO.
resilver_skip=0					# Should I skip processing pools in process of resilvering. 0 = NO
scrub_skip=0					# Should I skip processing pools in process of scrubing. 0 = NO
failures=0						# Number of failed actions.
count_failures=0				# Should I coundt failed actions? 0 = NO
zpool28fix=0					# Workaround for zpool v28 zfs destroy -r bug

while [ "$1" = '-d' -o "$1" = '-v' -o "$1" = '-n' -o "$1" = '-F' -o "$1" = '-z' -o "$1" = '-s' -o "$1" = '-S' -o "$1" = '-e' -o "$1" = '-zpool28fix' ]; do
	case "$1" in
	'-d')
		delete_snapshots=1
		shift
		;;

	'-v')
		verbose=1
		shift
		;;

	'-n')
		dry_run=1
		shift
		;;

	'-F')
		force_delete_snapshots_age=`time2s $2`
		shift 2
		;;

	'-z')
		zero_seconds=1
		shift
		;;

	'-s')
		get_pools=1
		resilver_skip=1
		shift
		;;

	'-S')
		get_pools=1
		scrub_skip=1
		shift
		;;

	'-e')
		count_failures=1
		shift
		;;

	'-zpool28fix')
		zpool28fix=1
		shift
		;;

	esac
done

if [ $get_pools -ne 0 ]; then
	pools=`$zpool_cmd list -H -o name`
	for i in $pools; do
		if [ $resilver_skip -ne 0 ]; then
			$zpool_cmd status $i | grep -q -e 'resilver in progress' && resilver_pools="$resilver_pools $i"
		fi
		if [ $scrub_skip -ne 0 ]; then
			$zpool_cmd status $i | grep -q -e 'scrub in progress' && scrub_pools="$scrub_pools $i"
		fi
	done
fi

readonly date_pattern='20[0-9][0-9]-[01][0-9]-[0-3][0-9]_[0-2][0-9]\.[0-5][0-9]\.[0-5][0-9]'
if [ $zero_seconds -eq 0 ]; then
	readonly tfrmt='%Y-%m-%d_%H.%M.%S'
else
	readonly tfrmt='%Y-%m-%d_%H.%M.00'
fi

readonly htime_pattern='([0-9]+y)?([0-9]+m)?([0-9]+w)?([0-9]+d)?([0-9]+h)?([0-9]+M)?([0-9]+[s]?)?'


[ $dry_run -ne 0 ] && zfs_list=`$zfs_cmd list -H -o name`
ntime=`date "+$tfrmt"`
while [ "$1" ]; do
	while [ "$1" = '-r' -o "$1" = '-R' -o "$1" = '-a' -o "$1" = '-p' -o "$1" = '-P' -o "$1" = '-D' ]; do
		case "$1" in
		'-r')
			zopt='-r'
			shift
			;;
		'-R')
			zopt=''
			shift
			;;
		'-a')
			ttl="$2"
			echo "$ttl" | grep -q -E -e "^[0-9]+$" && ttl=`s2time $ttl`
			shift 2
			;;
		'-p')
			prefx="$2"
			prefxes="$prefxes|$prefx"
			shift 2
			;;
		'-P')
			prefx=""
			shift
			;;
		'-D')
			if [ "$zopt" != '-r' ]; then
				delete_specific_fs_snapshots="$delete_specific_fs_snapshots $2"
			else
				delete_specific_fs_snapshots_recursively="$delete_specific_fs_snapshots_recursively $2"
			fi
			shift 2
			;;

		esac
	done

	# create snapshots
	if [ $1 ]; then
		if skip_pool $1; then
			if [ $1 = `echo $1 | $ESED -e 's/^-//'` ]; then
				zfs_snapshot="$zfs_cmd snapshot $zopt $1@${prefx}${ntime}--${ttl}${postfx}"
				if [ $dry_run -eq 0 ]; then
					if $zfs_snapshot > /dev/stderr; then
						[ $verbose -ne 0 ] && echo "$zfs_snapshot	... DONE"
					else
						[ $verbose -ne 0 ] && echo "$zfs_snapshot	... FAIL"
						[ $count_failures -ne 0 ] && failures=$(($failures + 1))
					fi
				else
					printf "%s\n" $zfs_list | grep -m 1 -q -E -e "^$1$" \
						&& echo "$zfs_snapshot" \
						|| echo "ERR: Looks like zfs filesystem '$1' doesn't exist" > /dev/stderr
				fi
			else
				echo "WARN: '$1' doesn't look like valid argument. Ignoring" > /dev/stderr
			fi
		fi
		shift
	fi
done

prefxes=`echo "$prefxes" | sed -e 's/^\|//'`

# delete snapshots
if [ $delete_snapshots -ne 0 -o $force_delete_snapshots_age -ne -1 ]; then

	if [ $zpool28fix -eq 0 ]; then
		zfs_snapshots=`$zfs_cmd list -H -o name -t snapshot | grep -E -e "^.*@(${prefxes})?${date_pattern}--${htime_pattern}$" | sed -e 's#/.*@#@#'`
	else
		zfs_snapshots=`$zfs_cmd list -H -o name -t snapshot | grep -E -e "^.*@(${prefxes})?${date_pattern}--${htime_pattern}$"`
	fi

	current_time=`date +%s`
	for i in `echo $zfs_snapshots | xargs printf "%s\n" | $ESED -e "s/^.*@//" | sort -u`; do
		create_time=$(date2timestamp `echo "$i" | $ESED -e "s/--${htime_pattern}$//; s/^(${prefxes})?//"`)
		if [ $delete_snapshots -ne 0 ]; then
			stay_time=$(time2s `echo $i | $ESED -e "s/^(${prefxes})?${date_pattern}--//"`)
			[ $current_time -gt $(($create_time + $stay_time)) ] \
				&& rm_snapshot_pattern="$rm_snapshot_pattern $i"
		fi
		if [ "$force_delete_snapshots_age" -ne -1 ]; then
			[ $current_time -gt $(($create_time + $force_delete_snapshots_age)) ] \
				&& rm_snapshot_pattern="$rm_snapshot_pattern $i"
		fi
	done

	if [ "$rm_snapshot_pattern" != '' ]; then
		rm_snapshots=$(echo $zfs_snapshots | xargs printf '%s\n' | grep -E -e "@`echo $rm_snapshot_pattern | sed -e 's/ /|/g'`" | sort -u)
		for i in $rm_snapshots; do
			rm_zfs_snapshot -r $i
		done
	fi
fi

# delete all snap
if [ "$delete_specific_snapshots" != '' ]; then
	if [ "$delete_specific_fs_snapshots" != '' ]; then
		rm_snapshots=`$zfs_cmd list -H -o name -t snapshot | grep -E -e "^($(echo "$delete_specific_fs_snapshots" | tr ' ' '|'))@(${prefxes})?${date_pattern}--${htime_pattern}$"`
		for i in $rm_snapshots; do
			rm_zfs_snapshot $i
		done
	fi

	if [ "$delete_specific_fs_snapshots_recursively" != '' ]; then
		rm_snapshots=`$zfs_cmd list -H -o name -t snapshot | grep -E -e "^($(echo "$delete_specific_fs_snapshots_recursively" | tr ' ' '|'))@(${prefxes})?${date_pattern}--${htime_pattern}$"`
		for i in $rm_snapshots; do
			rm_zfs_snapshot -r $i
		done
	fi
fi


[ $count_failures -ne 0 ] && exit $failures
exit 0
# vim: set ts=4 sw=4:
