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
ZFS_CMD='/sbin/zfs'
ZPOOL_CMD='/sbin/zpool'

# VARIABLES
TTL='1m'                            # default snapshot ttl
VERBOSE="false"                     # Verbose output?
DRY_RUN="false"                     # Dry run?
POOLS=""                            # List of pools
SKIP_POOLS=""                       # List of pools to skip

readonly OS=`uname`
readonly TTL_PATTERN="([0-9]+y)?([0-9]+m)?([0-9]+w)?([0-9]+d)?([0-9]+h)?([0-9]+M)?([0-9]+[s])?"
readonly DATE_PATTERN='20[0-9][0-9]-[01][0-9]-[0-3][0-9]_[0-2][0-9]\.[0-5][0-9]\.[0-5][0-9]'
TEST_MODE="${TEST_MODE:-false}"     # When set to "true", Exit won't really exit
TIME_FORMAT='%Y-%m-%d_%H.%M.%S'     # format for snapshot creation

## FUNCTIONS

Err() {
    printf '%s\n' "ERROR: $*" > /dev/stderr
}
Exit() {
    IsTrue $TEST_MODE || exit $1
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
        # normalize the date
        local the_date="$1"
        while [ -z "${the_date##*[_.]*}" ]; do
            case "$the_date" in
                *_*) the_date="${the_date%%_*} ${the_date#*_}" ;;
                *.*) the_date="${the_date%%.*}:${the_date#*.}" ;;
                  *) Fatal "Normalizing '$the_date' failed!" ;;
            esac
        done

        date --date "$the_date" '+%s'
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

# Populates the $SKIP_POOLS global variable; does not return anything
PopulateSkipPools() {
    [ "$1" ] || Fatal "PopulateSkipPools requires an argument!"
    POOLS="${POOLS:-`$ZPOOL_CMD list -H -o name`}"

    for i in $POOLS; do
        $ZPOOL_CMD status $i | grep -q -e "$1 in progress" && SKIP_POOLS="$SKIP_POOLS $i"
    done
}

# Removes zfs snapshot
RmZfsSnapshot() {
    SkipPool $1 || return 1

    zfs_destroy="$ZFS_CMD destroy $*"

    # hardening: make really, really sure we are deleting snapshot
    if IsSnapshot "$1"; then
        if IsFalse $DRY_RUN; then
            if $zfs_destroy > /dev/stderr; then
                IsTrue $VERBOSE && echo "$zfs_destroy  ... DONE"
            else
                IsTrue $VERBOSE && echo "$zfs_destroy  ... FAIL"
            fi
        else
            echo "$zfs_destroy"
        fi
    else
        echo "FATAL: trying to delete zfs pool or filesystem? WTF?" > /dev/stderr
        echo "  This is bug, we definitely don't want that." > /dev/stderr
        echo "  Please report it to https://github.com/graudeejs/zfSnap/issues" > /dev/stderr
        echo "  Don't panic, nothing was deleted :)" > /dev/stderr
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
    for i in $SKIP_POOLS; do
        if [ "${1%%[/@]*}" = "$i" ]; then
            IsTrue $VERBOSE && Note "No actions will be performed on '$1'. Resilver or Scrub is running on pool."
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

# Returns 0 if the TTL is valid; Returns 1 if the TTL is invalid
ValidTTL() {
    ttl="$1"

    [ "$ttl" = '' ] && return 1

    while [ "$ttl" ]; do
        case "$ttl" in
            *y*) [ ${ttl%y*} -gt 0 2> /dev/null ] && ttl=${ttl##*y} || return 1 ;;
            *m*) [ ${ttl%m*} -gt 0 2> /dev/null ] && ttl=${ttl##*m} || return 1 ;;
            *w*) [ ${ttl%w*} -gt 0 2> /dev/null ] && ttl=${ttl##*w} || return 1 ;;
            *d*) [ ${ttl%d*} -gt 0 2> /dev/null ] && ttl=${ttl##*d} || return 1 ;;
            *h*) [ ${ttl%h*} -gt 0 2> /dev/null ] && ttl=${ttl##*h} || return 1 ;;
            *M*) [ ${ttl%M*} -gt 0 2> /dev/null ] && ttl=${ttl##*M} || return 1 ;;
             *s) [ ${ttl%s*} -gt 0 2> /dev/null ] && ttl=${ttl##*s} || return 1 ;;
              *) return 1 ;;
        esac
    done

    return 0
}

## MAIN
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
        ZFS_CMD='/usr/sbin/zfs'
        ZPOOL_CMD='/usr/sbin/zpool'
        ;;
    *)
        Fatal "Your OS isn't supported"
        ;;
esac
