#!/bin/sh

# "THE BEER-WARE LICENSE":
# <aldis@bsdroot.lv> wrote this file. As long as you retain this notice you
# can do whatever you want with this stuff. If we meet some day, and you think
# this stuff is worth it, you can buy me a beer in return. Aldis Berjoza

# wiki: 		http://wiki.bsdroot.lv/zfsnap
# repository:		http://aldis.git.bsdroot.lv/zfSnap/
# project email:	zfsnap@bsdroot.lv

readonly VERSION=1.7.0
readonly zfs_cmd=/sbin/zfs

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
${0##*/} v${VERSION} by Aldis Berjoza
zfsnap project e-mail: zfsnap@bsdroot.lv

Syntax:
${0##*/} [ generic options ] [[[ -a ttl ] [ -r|-R ] z/fs1 ] | [ -r|-R ] -D z/fs2 ] ...

GENERIC OPTIONS:
  -F age       = Force delete all snapshots exceeding age
  -d           = delete old snapshots
  -n           = only show actions that would be performed
  -v           = verbose output
  -o           = use old timestamp format used before v1.4.0 (for backward
                 compability)
  -z           = force new snapshots to have 00 seconds!

OPTIONS:
  -P           = don't use prefix for snapshots after this switch
  -R           = create non-recursive snapshots for all zfs file systems
                 that fallow this switch
  -a ttl       = set how long snapshot should be kept
  -p prefix    = use prefix for snapshots after this switch
  -r           = create recursive snapshots for all zfs file systems that
                 fallow this switch
  -D pool/fs   = delete all zfSnap snapshots of specific pool/fs (ignore ttl)

MORE INFO:
  http://wiki.bsdroot.lv/zfsnap

EOF
	exit
}

rm_zfs_snapshot() {
	zfs_destroy="$zfs_cmd destroy $*"
	if [ $dry_run -eq 0 ]; then
		# hardening: make really, really sure we are deleting snapshot
		echo $i | grep -q -e '@'
		if [ $? -eq 0 ]; then
			$zfs_destroy > /dev/stderr && { [ $verbose -eq 1 ] && echo "$zfs_destroy	... DONE"; }
		else
			{
				echo "ERR: trying to delete zfs pool or filesystem? WTF?"
				echo "  This is bug, we definitely don't want that."
				echo "  Please report it to zfsnap@bsdroot.lv"
				echo "  Don't panic, nothing was deleted :)"
				exit 1
			} > /dev/stderr
		fi
	else
		echo "$zfs_destroy"
	fi
}


[ $# = 0 ] && help
[ "$1" = '-h' -o $1 = "--help" ] && help

ttl='1m'	# default snapshot ttl
force_delete_snapshots_age=-1
delete_snapshots=0
delete_specific_snapshots=0
verbose=0
dry_run=0
old_format=0
prefx=""	# default pretfix
prefxes=""
delete_specific_fs_snapshots=""
delete_specific_fs_snapshots_recursively=""
zero_seconds=0

while [ "$1" = '-d' -o "$1" = '-v' -o "$1" = '-n' -o "$1" = '-F' -o "$1" = '-o' -o "$1" = '-z' ]; do
	if [ "$1" = "-d" ]; then
		delete_snapshots=1
		shift
	fi
	if [ "$1" = "-v" ]; then
		verbose=1
		shift
	fi
	if [ "$1" = "-n" ]; then
		dry_run=1
		shift
	fi
	if [ "$1" = "-F" ]; then
		force_delete_snapshots_age=`time2s $2`
		shift 2
	fi
	if [ "$1" = "-o" ]; then
		old_format=1
		shift
	fi
	if [ "$1" = "-z" ]; then
		zero_seconds=1
		shift
	fi
done


if [ "$old_format" -eq 0 ]; then
	# new format (easier to navigate snapshots using shell)
	if [ $zero_seconds -eq 0 ]; then
		readonly tfrmt='%F_%H.%M.%S'
	else
		readonly tfrmt='%F_%H.%M.00'
	fi

	readonly date_pattern='20[0-9][0-9]-[01][0-9]-[0-3][0-9]_[0-2][0-9]\.[0-5][0-9]\.[0-5][0-9]'
else
	# old format
	if [ $zero_seconds -eq 0 ]; then
		readonly tfrmt='%F_%H:%M:%S'
	else
		readonly tfrmt='%F_%H:%M:00'
	fi

	readonly date_pattern='20[0-9][0-9]-[01][0-9]-[0-3][0-9]_[0-2][0-9]:[0-5][0-9]:[0-5][0-9]'
fi

readonly htime_pattern='([0-9]+y)?([0-9]+m)?([0-9]+w)?([0-9]+d)?([0-9]+h)?([0-9]+M)?([0-9]+[s]?)?'


[ $dry_run -eq 1 ] && zfs_list=`$zfs_cmd list -H | awk '{print $1}'`
ntime=`date "+$tfrmt"`
while [ "$1" ]; do
	while [ "$1" = '-r' -o "$1" = '-R' -o "$1" = '-a' -o "$1" = '-p' -o "$1" = '-P' -o "$1" = '-D' ]; do
		if [ "$1" = '-r' ]; then
			zopt='-r'
			shift
		fi
		if [ "$1" = '-R' ]; then
			zopt=''
			shift
		fi
		if [ "$1" = '-a' ]; then
			ttl="$2"
			echo "$ttl" | grep -q -E -e "^[0-9]+$" && ttl=`s2time $ttl`
			shift 2
		fi
		if [ "$1" = '-p' ]; then
			prefx="$2"
			prefxes="$prefxes|$prefx"
			shift 2 
		fi
		if [ "$1" = '-P' ]; then 
			prefx=""
			shift
		fi
		if [ "$1" = '-D' ]; then
			if [ "$zopt" != '-r' ]; then
				delete_specific_fs_snapshots="$delete_specific_fs_snapshots $2"
			else
				delete_specific_fs_snapshots_recursively="$delete_specific_fs_snapshots_recursively $2"
			fi
			shift 2
		fi
	done

	# create snapshots
	if [ $1 ]; then
		if [ $1 = `echo $1 | sed -E -e 's/^-//'` ]; then
			zfs_snapshot="$zfs_cmd snapshot $zopt $1@${prefx}${ntime}--${ttl}${postfx}"
			if [ $dry_run -eq 0 ]; then
				$zfs_snapshot > /dev/stderr \
					&& { [ $verbose -eq 1 ] && echo "$zfs_snapshot	... DONE"; } \
					|| { [ $verbose -eq 1 ] && echo "$zfs_snapshot	... FAIL"; }
			else
				good_fs=0
				printf "%s\n" $zfs_list | grep -m 1 -q -E -e "^$1$" \
					&& echo "$zfs_snapshot" \
					|| echo "ERR: Looks like zfs filesystem '$1' doesn't exist" > /dev/stderr
			fi
		else
			echo "WARN: '$1' doesn't look like valid argument. Ignoring" > /dev/stderr
		fi
		shift
	fi
done

prefxes=`echo "$prefxes" | sed -e 's/^\|//'`

# delete snapshots
if [ "$delete_snapshots" -eq 1 -o "$force_delete_snapshots_age" -ne -1 ]; then
	zfs_snapshots=`$zfs_cmd list -H -t snapshot | awk '{print $1}' | grep -E -e "^.*@(${prefxes})?${date_pattern}--${htime_pattern}$" | sed -e 's#/.*@#@#'`

	current_time=`date +%s`
	for i in `echo $zfs_snapshots | xargs printf "%s\n" | sed -E -e "s/^.*@//" | sort -u`; do
		create_time=$(date -j -f "$tfrmt" $(echo "$i" | sed -E -e "s/--${htime_pattern}$//" -E -e "s/^(${prefxes})?//") +%s)
		if [ "$delete_snapshots" -eq 1 ]; then
			stay_time=$(time2s `echo $i | sed -E -e "s/^(${prefxes})?${date_pattern}--//"`)
			[ $current_time -gt `expr $create_time + $stay_time` ] \
				&& rm_snapshot_pattern="$rm_snapshot_pattern $i"
		fi
		if [ "$force_delete_snapshots_age" -ne -1 ]; then
			[ $current_time -gt `expr $create_time + $force_delete_snapshots_age` ] \
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
if [ "$delete_specific_snapshots" ]; then
	if [ "$delete_specific_fs_snapshots" ]; then
		rm_snapshots=`$zfs_cmd list -H -t snapshot | awk '{print $1}' | grep -E -e "^($(echo "$delete_specific_fs_snapshots" | tr ' ' '|'))@(${prefxes})?${date_pattern}--${htime_pattern}$"`
		for i in $rm_snapshots; do
			rm_zfs_snapshot $i
		done
	fi

	if [ "$delete_specific_fs_snapshots_recursively" ]; then
		rm_snapshots=`$zfs_cmd list -H -t snapshot | awk '{print $1}' | grep -E -e "^($(echo "$delete_specific_fs_snapshots_recursively" | tr ' ' '|'))@(${prefxes})?${date_pattern}--${htime_pattern}$"`
		for i in $rm_snapshots; do
			rm_zfs_snapshot -r $i
		done
	fi
fi

exit 0
