#!/bin/sh

# "THE BEER-WARE LICENSE":
# <graudeejs@yandex.com> wrote this file. As long as you retain this notice you
# can do whatever you want with this stuff. If we meet some day, and you think
# this stuff is worth it, you can buy me a beer in return. Aldis Berjoza

# wiki:             https://github.com/graudeejs/zfSnap/wiki
# repository:       https://github.com/graudeejs/zfSnap
# Bug tracking:     https://github.com/graudeejs/zfSnap/issues

readonly VERSION=1.11.1

# commands
ESED='sed -E'
zfs_cmd='/sbin/zfs'
zpool_cmd='/sbin/zpool'

# global variables
readonly ttl_pattern="([0-9]+y)?([0-9]+m)?([0-9]+w)?([0-9]+d)?([0-9]+h)?([0-9]+M)?([0-9]+[s])?"
readonly date_pattern='20[0-9][0-9]-[01][0-9]-[0-3][0-9]_[0-2][0-9]\.[0-5][0-9]\.[0-5][0-9]'
test_mode="${test_mode:-false}"     # When set to "true", Exit won't really exit
time_format='%Y-%m-%d_%H.%M.%S'     # format for snapshot creation

# Exit program with given status code
Exit() {
    IsTrue $test_mode || exit $1
}

Note() {
    printf '%s\n' "NOTE: $*" > /dev/stderr
}

Err() {
    printf '%s\n' "ERROR: $*" > /dev/stderr
}

Fatal() {
    printf '%s\n' "FATAL: $*" > /dev/stderr
    exit 1
}

Warn() {
    printf '%s\n' "WARNING: $*" > /dev/stderr
}


readonly OS=`uname`
case $OS in
    'FreeBSD')
        ;;
    'SunOS')
        ESED='sed -r'
        if [ -d "/usr/gnu/bin" ]; then
            export PATH="/usr/gnu/bin:$PATH"
        else
            Fatal "GNU bin direcotry not found"
        fi
        ;;
    'Linux')
        ESED='sed -r'
        ;;
    'Darwin')
        zfs_cmd='/usr/sbin/zfs'
        zpool_cmd='/usr/sbin/zpool'
        ;;
    *)
        Fatal "Your OS isn't supported"
        ;;
esac


# Returns 0 if argument is "true"
IsTrue() {
    case "$1" in
        true)
            return 0
            ;;
        false)
            return 1
            ;;
        *)
            Fatal "must be true or false"
            ;;
    esac
}

# Returns 0 if argument is "false"
IsFalse() {
    IsTrue "$1" && return 1 || return 0
}

# Converts seconds to TTL
Seconds2TTL() {
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

# Converts TTL to seconds
TTL2Seconds() {
    # convert human readable time to seconds
    echo "$1" | sed -e 's/y/*31536000+/g; s/m/*2592000+/g; s/w/*604800+/g; s/d/*86400+/g; s/h/*3600+/g; s/M/*60+/g; s/s//g; s/\+$//' | bc -l
}

# Converts datetime to seconds
Date2Timestamp() {
    case $OS in
    'FreeBSD' | 'Darwin' )
        date -j -f '%Y-%m-%d_%H.%M.%S' "$1" '+%s'
        ;;
    *)
        date_normal="`echo $1 | $ESED -e 's/\./:/g; s/(20[0-9][0-9]-[01][0-9]-[0-3][0-9])_([0-2][0-9]:[0-5][0-9]:[0-5][0-9])/\1 \2/'`"
        date --date "$date_normal" '+%s'
        ;;
    esac
}

# Check validity of TTL
ValidTTL() {
    printf "%s" "$1" | grep -E "^${ttl_pattern}$" > /dev/null
}

Help() {
    cat << EOF
${0##*/} v${VERSION} by Aldis Berjoza

Syntax:
${0##*/} [ options ] zpool/filesystem ...

OPTIONS:
  -a ttl       = Set how long snapshot should be kept
  -d           = Delete old snapshots
  -D pool/fs   = Delete all zfSnap snapshots of specific pool/fs (ignore ttl)
  -e           = Return number of failed actions as exit code.
  -F age       = Force delete all snapshots exceeding age
  -h           = Print this help and exit.
  -n           = Only show actions that would be performed
  -p prefix    = Use prefix for snapshots after this switch
  -P           = Don't use prefix for snapshots after this switch
  -r           = Create recursive snapshots for all zfs file systems that
                 follow this switch
  -R           = Create non-recursive snapshots for all zfs file systems that
                 follow this switch
  -s           = Don't do anything on pools running resilver
  -S           = Don't do anything on pools running scrub
  -v           = Verbose output
  -z           = Force new snapshots to have 00 seconds!

LINKS:
  wiki:             https://github.com/graudeejs/zfSnap/wiki
  repository:       https://github.com/graudeejs/zfSnap
  Bug tracking:     https://github.com/graudeejs/zfSnap/issues

EOF
    Exit 0
}

# Removes zfs snapshot
RmZfsSnapshot() {
    if IsTrue $zpool28fix && [ "$1" = '-r' ]; then
        # get rid of '-r' parameter
        RmZfsSnapshot $2
        return
    fi

    if [ "$1" = '-r' ]; then
        SkipPool $2 || return 1
    else
        SkipPool $1 || return 1
    fi

    zfs_destroy="$zfs_cmd destroy $*"

    # hardening: make really, really sure we are deleting snapshot
    if echo $* | grep -q -e '@'; then
        if IsFalse $dry_run; then
            if $zfs_destroy > /dev/stderr; then
                IsTrue $verbose && echo "$zfs_destroy  ... DONE"
            else
                IsTrue $verbose && echo "$zfs_destroy  ... FAIL"
                IsTrue $count_failures && failures=$(($failures + 1))
            fi
        else
            echo "$zfs_destroy"
        fi
    else
        echo "FATAL: trying to delete zfs pool or filesystem? WTF?" > /dev/stderr
        echo "  This is bug, we definitely don't want that." > /dev/stderr
        echo "  Please report it to https://github.com/graudeejs/zfSnap/issues" > /dev/stderr
        echo "  Don't panic, nothing was deleted :)" > /dev/stderr
        IsTrue $count_failures && [ $failures -gt 0 ] && Exit $failures
        Exit 1
    fi
}

# Returns 1 if ZFS operations on given pool should be skipped
SkipPool() {
    for i in "$skip_pools"; do
        if [ `printf '%s' "$1" | sed -e 's#/.*$##; s/@.*//'` = "$i" ]; then
            IsTrue $verbose && Note "No actions will be performed on '$1'. Resilver or Scrub is running on pool."
            return 1
        fi
    done
    return 0
}

ttl='1m'                            # default snapshot ttl
force_delete_snapshots_age=-1       # Delete snapshots older than x seconds. -1 means NO
delete_snapshots="false"            # Delete old snapshots?
verbose="false"                     # Verbose output?
dry_run="false"                     # Dry run?
prefix=""                           # Default prefix
prefixes=""                         # List of prefixes
delete_specific_fs_snapshots=""     # List of specific snapshots to delete
delete_specific_fs_snapshots_recursively="" # List of specific snapshots to delete recursively
pools=""                            # List of pools
skip_pools=""                       # List of pools to skip
failures=0                          # Number of failed actions.
count_failures="false"              # Should I count failed actions?
zpool28fix="true"                   # Workaround for zpool v28 zfs destroy -r bug

# make sure arguments were provided
if [ "$#" -eq 0 ] && IsFalse $test_mode; then
    Help
fi

# main loop; get options, process snapshot creation
while [ "$1" ]; do
    while getopts :a:dD:eF:hnp:PrRsSvz opt; do
        case "$opt" in
            a) ttl="$OPTARG"
               printf "%s" "$ttl" | grep -q -E -e "^[0-9]+$" && ttl=`Seconds2TTL "$ttl"`
               ValidTTL "$ttl" || Fatal "Invalid TTL: $ttl"
               ;;
            d) delete_snapshots="true";;
            D) if [ "$zopt" != '-r' ]; then
                   delete_specific_fs_snapshots="$delete_specific_fs_snapshots $OPTARG"
               else
                   delete_specific_fs_snapshots_recursively="$delete_specific_fs_snapshots_recursively $OPTARG"
               fi
               ;;
            e) count_failures="true";;
            F) force_delete_snapshots_age=`TTL2Seconds "$OPTARG"`;;
            h) Help;;
            n) dry_run="true";;
            p) prefix="$OPTARG"; prefixes="${prefixes:+$prefixes|}$prefix";;
            P) prefix="";;
            r) zopt='-r';;
            R) zopt='';;
            s) pools="${pools:-`$zpool_cmd list -H -o name`}"
               for i in "$pools"; do
                   $zpool_cmd status $i | grep -q -e 'resilver in progress' && skip_pools="$skip_pools $i"
               done
               ;;
            S) pools="${pools:-`$zpool_cmd list -H -o name`}"
               for i in "$pools"; do
                   $zpool_cmd status $i | grep -q -e 'scrub in progress' && skip_pools="$skip_pools $i"
               done
               ;;
            v) verbose="true";;
            z) time_format='%Y-%m-%d_%H.%M.00';;

            :) Fatal "Option -$OPTARG requires an argument.";;
           \?) Fatal "Invalid option: -$OPTARG";;
        esac
    done

    # discard all arguments processed thus far
    shift $(($OPTIND - 1))

    # create snapshots
    if [ "$1" ]; then
        if SkipPool "$1"; then
            ntime="${ntime:-`date "+$time_format"`}"
            IsTrue $dry_run && zfs_list="${zfs_list:-`$zfs_cmd list -H -o name`}"

            zfs_snapshot="$zfs_cmd snapshot $zopt $1@${prefix}${ntime}--${ttl}"
            if IsFalse $dry_run; then
                if $zfs_snapshot > /dev/stderr; then
                    IsTrue $verbose && echo "$zfs_snapshot ... DONE"
                else
                    IsTrue $verbose && echo "$zfs_snapshot ... FAIL"
                    IsTrue $count_failures && failures=$(($failures + 1))
                fi
            else
                printf "%s\n" $zfs_list | grep -m 1 -q -E -e "^$1$" \
                    && echo "$zfs_snapshot" \
                    || Err "Looks like ZFS filesystem '$1' doesn't exist"
            fi
        fi
        shift
    fi
done

# delete snapshots
if IsTrue $delete_snapshots || [ $force_delete_snapshots_age -ne -1 ]; then

    if IsFalse $zpool28fix; then
        zfs_snapshots=`$zfs_cmd list -H -o name -t snapshot | grep -E -e "^.*@(${prefixes})?${date_pattern}--${ttl_pattern}$" | sed -e 's#/.*@#@#'`
    else
        zfs_snapshots=`$zfs_cmd list -H -o name -t snapshot | grep -E -e "^.*@(${prefixes})?${date_pattern}--${ttl_pattern}$"`
    fi

    current_time=`date +%s`
    for i in `echo $zfs_snapshots | xargs printf "%s\n" | $ESED -e "s/^.*@//" | sort -u`; do
        create_time=$(Date2Timestamp `echo "$i" | $ESED -e "s/--${ttl_pattern}$//; s/^(${prefixes})?//"`)
        if IsTrue $delete_snapshots; then
            stay_time=$(TTL2Seconds `echo $i | $ESED -e "s/^(${prefixes})?${date_pattern}--//"`)
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
            RmZfsSnapshot -r $i
        done
    fi
fi

# delete all snapshots
if [ "$delete_specific_fs_snapshots" != '' ]; then
    rm_snapshots=`$zfs_cmd list -H -o name -t snapshot | grep -E -e "^($(echo "$delete_specific_fs_snapshots" | tr ' ' '|'))@(${prefixes})?${date_pattern}--${ttl_pattern}$"`
    for i in $rm_snapshots; do
        RmZfsSnapshot $i
    done
fi

if [ "$delete_specific_fs_snapshots_recursively" != '' ]; then
    rm_snapshots=`$zfs_cmd list -H -o name -t snapshot | grep -E -e "^($(echo "$delete_specific_fs_snapshots_recursively" | tr ' ' '|'))@(${prefixes})?${date_pattern}--${ttl_pattern}$"`
    for i in $rm_snapshots; do
        RmZfsSnapshot -r $i
    done
fi


IsTrue $count_failures && Exit $failures
Exit 0
# vim: set ts=4 sw=4 expandtab:
