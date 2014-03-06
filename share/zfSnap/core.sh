#!/bin/sh

# "THE BEER-WARE LICENSE":
# <graudeejs@yandex.com> wrote this file. As long as you retain this notice you
# can do whatever you want with this stuff. If we meet some day, and you think
# this stuff is worth it, you can buy me a beer in return. Aldis Berjoza

# wiki:             https://github.com/graudeejs/zfSnap/wiki
# repository:       https://github.com/graudeejs/zfSnap
# Bug tracking:     https://github.com/graudeejs/zfSnap/issues

readonly VERSION=2.0.0.pre

# COMMANDS
ESED='sed -E'
zfs_cmd='/sbin/zfs'
zpool_cmd='/sbin/zpool'

# VARIABLES
ttl='1m'                            # default snapshot ttl
force_delete_snapshots_age=-1       # Delete snapshots older than x seconds. -1 means NO
delete_snapshots="false"            # Delete old snapshots?
verbose="false"                     # Verbose output?
dry_run="false"                     # Dry run?
prefix=""                           # Default prefix
prefixes=""                         # List of prefixes
recursive='false'                   # Operate on child pools??
delete_specific_fs_snapshots=""     # List of specific snapshots to delete
delete_specific_fs_snapshots_recursively="" # List of specific snapshots to delete recursively
pools=""                            # List of pools
skip_pools=""                       # List of pools to skip
failures=0                          # Number of failed actions.
count_failures="false"              # Should I count failed actions?
zpool28fix="true"                   # Workaround for zpool v28 zfs destroy -r bug

readonly ttl_pattern="([0-9]+y)?([0-9]+m)?([0-9]+w)?([0-9]+d)?([0-9]+h)?([0-9]+M)?([0-9]+[s])?"
readonly date_pattern='20[0-9][0-9]-[01][0-9]-[0-3][0-9]_[0-2][0-9]\.[0-5][0-9]\.[0-5][0-9]'
test_mode="${test_mode:-false}"     # When set to "true", Exit won't really exit
time_format='%Y-%m-%d_%H.%M.%S'     # format for snapshot creation

## FUNCTIONS

Err() {
    printf '%s\n' "ERROR: $*" > /dev/stderr
}
Exit() {
    IsTrue $test_mode || exit $1
}
Fatal() {
    printf '%s\n' "FATAL: $*" > /dev/stderr
    exit 1
}
Note() {
    printf '%s\n' "NOTE: $*" > /dev/stderr
}
Warn() {
    printf '%s\n' "WARNING: $*" > /dev/stderr
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

# Returns 0 if argument is "false"
IsFalse() {
    IsTrue "$1" && return 1 || return 0
}

# Returns 0 if it looks like a snapshot
IsSnapshot() {
    case "$1" in
        [!@]*@*[!@])
            return 0;;
        *)
            return 1;;
    esac
}

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

# Populates the $skip_pools global variable; does not return anything
PopulateSkipPools() {
    [ "$1" ] || Fatal "PopulateSkipPools requires an argument!"
    pools="${pools:-`$zpool_cmd list -H -o name`}"

    for i in "$pools"; do
        $zpool_cmd status $i | grep -q -e "$1 in progress" && skip_pools="$skip_pools $i"
    done
}

# Removes zfs snapshot
RmZfsSnapshot() {
    SkipPool $1 || return 1

    zfs_destroy="$zfs_cmd destroy $*"

    # hardening: make really, really sure we are deleting snapshot
    if IsSnapshot "$1"; then
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

# Returns 1 if ZFS operations on given pool should be skipped
# This function's name implies the opposite of what it does. It
# should be renamed, but I can't come up with anything intuitive and short.
SkipPool() {
    for i in $skip_pools; do
        if [ "${1%%[/@]*}" = "$i" ]; then
            IsTrue $verbose && Note "No actions will be performed on '$1'. Resilver or Scrub is running on pool."
            return 1
        fi
    done
    return 0
}

# Converts TTL to seconds
TTL2Seconds() {
    ttl="$1"
    seconds=0
    while [ "$ttl" ]; do
        case "$ttl" in
            *y*) seconds=$(($seconds + (${ttl%%y*} * 31536000))); ttl=${ttl##*y} ;;
            *m*) seconds=$(($seconds + (${ttl%%m*} * 2592000))); ttl=${ttl##*m} ;;
            *w*) seconds=$(($seconds + (${ttl%%w*} * 604800))); ttl=${ttl##*w} ;;
            *d*) seconds=$(($seconds + (${ttl%%d*} * 86400))); ttl=${ttl##*d} ;;
            *h*) seconds=$(($seconds + (${ttl%%h*} * 3600))); ttl=${ttl##*h} ;;
            *M*) seconds=$(($seconds + (${ttl%%M*} * 60))); ttl=${ttl##*M} ;;
             *s) seconds=$(($seconds + ${ttl%%s*})); ttl=${ttl##*s} ;;
              *) Fatal "TTL2Seconds could not convert '$1'!" ;;
        esac
    done

    printf "$seconds"
}

# Check validity of TTL
ValidTTL() {
    printf "%s" "$1" | grep -E "^${ttl_pattern}$" > /dev/null
}

## MAIN
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
