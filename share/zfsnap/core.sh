#!/bin/sh

# This file is licensed under the BSD-3-Clause license.
# See the AUTHORS and LICENSE files for more information.
#
# wiki:             https://github.com/zfsnap/zfsnap/wiki
# repository:       https://github.com/zfsnap/zfsnap
# Bug tracking:     https://github.com/zfsnap/zfsnap/issues

readonly VERSION=2.0.0.beta1

# COMMANDS
ZFS_CMD='/sbin/zfs'
ZPOOL_CMD='/sbin/zpool'

# VARIABLES
TTL='1m'                            # default snapshot TTL
VERBOSE="false"                     # Verbose output?
DRY_RUN="false"                     # Dry run?
POOLS=""                            # List of pools
FS_LIST=''                          # List of all ZFS filesystems
SKIP_POOLS=""                       # List of pools to skip

readonly OS=`uname`
readonly DATE_PATTERN='20[0-9][0-9]-[01][0-9]-[0-3][0-9]_[0-2][0-9]\.[0-5][0-9]\.[0-5][0-9]'
TEST_MODE="${TEST_MODE:-false}"     # When set to "true", Exit won't really exit
TIME_FORMAT='%Y-%m-%d_%H.%M.%S'     # date/time format for snapshot creation and comparison
RETVAL=''                           # used by functions so we can avoid spawning subshells

## HELPER FUNCTIONS
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

# Returns 0 if argument is "false"
IsFalse() {
    IsTrue "$1" && return 1 || return 0
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

## ZFSNAP FUNCTIONS

# Adds a TTL to a date
DatePlusTTL() {
    local orig_date="$1"
    local ttl="$2"

    # break date into components; strip leading zeros
    local y=${orig_date%%-*} && y=${y#0} && orig_date="${orig_date#*-}"
    local m=${orig_date%%-*} && m=${m#0} && orig_date="${orig_date#*-}"
    local d=${orig_date%%_*} && d=${d#0} && orig_date="${orig_date#*_}"
    local h=${orig_date%%.*} && h=${h#0} && orig_date="${orig_date#*.}"
    local M=${orig_date%%.*} && M=${M#0} && orig_date="${orig_date#*.}"
    local s=${orig_date} && s=${s#0}

    while [ "$ttl" ]; do
        case "$ttl" in
            *y*) y=$(( ${ttl%%y*} + ${y} )); ttl=${ttl#*y} ;;
            *m*) m=$(( ${ttl%%m*} + ${m} )); ttl=${ttl#*m} ;;
            *w*) d=$(( (${ttl%%w*} * 7) + ${d} )); ttl=${ttl#*w} ;;
            *d*) d=$(( ${ttl%%d*} + ${d} )); ttl=${ttl#*d} ;;
            *h*) h=$(( ${ttl%%h*} + ${h} )); ttl=${ttl#*h} ;;
            *M*) M=$(( ${ttl%%M*} + ${M} )); ttl=${ttl#*M} ;;
             *s) s=$(( ${ttl%%s*} + ${s} )); ttl=${ttl#*s} ;;
              *) Warn "Invalid TTL '$ttl' in DatePlusTTL." && RETVAL='' && return 1 ;;
        esac
    done

    # roll seconds into minutes into hours into days
    [ ${s} -ge 60 ] && M=$(( ${M} + ( ${s} / 60 ))) && s=$(( ${s} % 60 ))
    [ ${M} -ge 60 ] && h=$(( ${h} + ( ${M} / 60 ))) && M=$(( ${M} % 60 ))
    [ ${h} -ge 24 ] && d=$(( ${d} + ( ${h} / 24 ))) && h=$(( ${h} % 24 ))

    # days, months, years
    while true; do
        # roll months into years
        [ ${m} -gt 12 ] && y=$(( ${y} + ( ${m} / 12 ))) && m=$(( ${m} % 12 ))
        [ ${m} -eq 0 ] && m=1

        # roll days into months
        local month_lengths="31 28 31 30 31 30 31 31 30 31 30 31"
        local m_num=0
        local m_length
        for m_length in $month_lengths; do
            m_num=$((${m_num}+1))

            # skip if we're not to current month yet
            [ ${m} -gt ${m_num} ] && continue

            # adjust if february in a leap year
            [ $m_num -eq 2 ] && IsLeapYear "$y" && m_length=29

            [ $d -le $m_length ] && break 2

            d=$(( ${d} - ${m_length} )) && m=$((${m}+1))
        done
    done

    # pad with a zero
    [ ${#m} -eq 1 ] && m="0${m}" ; [ ${#d} -eq 1 ] && d="0${d}"
    [ ${#h} -eq 1 ] && h="0${h}" ; [ ${#M} -eq 1 ] && M="0${M}"
    [ ${#s} -eq 1 ] && s="0${s}"

    RETVAL="${y}-${m}-${d}_${h}.${M}.${s}" && return 0
}

# Accepts two /valid/ zfsnap dates
# Returns 0 if date1 is greater or equal
# Returns 1 if date2 is greater
GreaterDate() {
    local date1="$1"
    local date2="$2"

    while [ "$date1" ]; do
        [ ${date1%%[-_.]*} -gt ${date2%%[-_.]*} ] && return 0
        [ ${date1%%[-_.]*} -eq ${date2%%[-_.]*} ] || return 1

        # if no separators left (seconds), bail
        [ -z ${date1%%*[-_.]*} ] || break

        date1="${date1#*[-_.]}" && date2="${date2#*[-_.]}"
    done

    return 0
}

# Returns 0 if filesystem exists
FSExists() {
    FS_LIST="${FS_LIST:-`$ZFS_CMD list -H -o name`}"

    local i
    for i in $FS_LIST; do
        [ "$1" = "$i" ] && return 0
    done

    return 1
}

# Returns 0 if supplied year is a leap year
IsLeapYear() {
    local year="$1"
    [ "$year" ] || return 1

    [ $(( $year % 400 )) -eq 0 ] && return 0
    [ $(( $year % 100 )) -eq 0 ] && return 1
    [ $(( $year % 4 )) -eq 0 ] && return 0

    return 1
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

# Returns 0 if pool exists
PoolExists() {
    POOLS="${POOLS:-`$ZPOOL_CMD list -H -o name`}"

    local i
    for i in $POOLS; do
        [ "$1" = "$i" ] && return 0
    done

    return 1
}

# Populates the $SKIP_POOLS global variable; does not return anything
PopulateSkipPools() {
    [ "$1" ] || Fatal "PopulateSkipPools requires an argument!"
    POOLS="${POOLS:-`$ZPOOL_CMD list -H -o name`}"

    local i
    for i in $POOLS; do
        ZSTATUS=`"$ZPOOL_CMD" status "$i"`
        [ -z "${ZSTATUS##*$1 in progress*}" ] && SKIP_POOLS="$SKIP_POOLS $i"
    done
}

# Removes ZFS snapshot
RmZfsSnapshot() {
    SkipPool $1 || return 1

    local zfs_destroy="$ZFS_CMD destroy $*"

    # hardening: make really, really sure we are deleting snapshot
    if IsSnapshot "$1"; then
        if IsFalse $DRY_RUN; then
            if $zfs_destroy > /dev/stderr; then
                IsTrue $VERBOSE && printf "%s ... DONE\n" "$zfs_destroy"
            else
                IsTrue $VERBOSE && printf "%s ... FAIL\n" "$zfs_destroy"
            fi
        else
            printf "%s\n" "$zfs_destroy"
        fi
    else
        Fatal "Trying to delete ZFS pool or filesystem? WTF?" \
              "This is bug, and we definitely don't want that." \
              "Please report it to https://github.com/zfsnap/zfsnap/issues ." \
              "Don't panic, as nothing was deleted. :-)"
    fi
}

# Returns 1 if ZFS operations on given pool should be skipped.
# This function's name implies the opposite of what it does. It
# should be renamed, but I can't come up with anything intuitive and short.
SkipPool() {
    local i
    for i in $SKIP_POOLS; do
        if TrimToPool "$1" && [ "$RETVAL" = "$i" ]; then
            IsTrue $VERBOSE && Note "No actions will be performed on '$1'. Resilver or Scrub is running on pool."
            return 1
        fi
    done
    return 0
}

# Retvals the date (anything that matches the "date pattern")
# If no "date pattern" is found, it will return 1.
TrimToDate() {
    local snapshot_name="$1"
    [ -z "$snapshot_name" ] && RETVAL='' && return 1

    # make sure it contains a date
    [ "${snapshot_name##*$DATE_PATTERN*}" ] && RETVAL='' && return 1

    local pre_date="${snapshot_name%$DATE_PATTERN*}"
    local post_date="${snapshot_name##*$DATE_PATTERN}"

    local snapshot_date="${snapshot_name##$pre_date}"
    snapshot_date="${snapshot_date%%$post_date}"

    if [ -z "${snapshot_date##$DATE_PATTERN}" ]; then
        RETVAL="$snapshot_date" && return 0
    else
        RETVAL='' && return 1
    fi
}

# Retvals the file system name (everything before the '@')
# ZFS reserves '@' to deliminate snapshots. At max, there will be one per dataset.
# If no valid file system is found, it will return 1.
TrimToFileSystem() {
    local snapshot="$1"
    local file_system="${snapshot%%@*}"

    if FSExists "$file_system"; then
        RETVAL="$file_system" && return 0
    else
        RETVAL='' && return 1
    fi
}

# Retvals the pool name (anything before the first '/' or '@')
# If no valid pool is found, it will return 1.
TrimToPool() {
    local pool_name="${1%%[/@]*}"

    if PoolExists "$pool_name"; then
        RETVAL="$pool_name" && return 0
    else
        RETVAL='' && return 1
    fi
}

# Retvals the prefix in a snapshot name (anything prior to the "snapshot date")
# If no valid "snapshot date" or prefix is found, it will return 1.
TrimToPrefix() {
    local snapshot_name="$1"

    # make sure it contains a date
    [ "${snapshot_name##*$DATE_PATTERN*}" ] && RETVAL='' && return 1

    local snapshot_prefix="${snapshot_name%$DATE_PATTERN*}"
    if ValidPrefix "$snapshot_prefix"; then
        RETVAL="$snapshot_prefix" && return 0
    else
        RETVAL='' && return 1
    fi
}

# Retvals the snapshot name (everything after the '@')
# ZFS reserves '@' to deliminate snapshots. At max, there will be one per dataset.
# If no valid snapshot name is found, it will return 1.
TrimToSnapshotName() {
    local snapshot="$1"
    local snapshot_name="${snapshot##*@}"

    if ValidSnapshotName "$snapshot_name"; then
        RETVAL="$snapshot_name" && return 0
    else
        RETVAL='' && return 1
    fi
}

# Retvals the TTL (anything after the last '--')
# If no valid TTL is found, it will return 1.
TrimToTTL() {
    local snapshot="$1"
    local ttl="${snapshot##*--}"

    if ValidTTL "$ttl"; then
        RETVAL="$ttl" && return 0
    else
        RETVAL='' && return 1
    fi
}

# Check validity of a prefix
ValidPrefix() {
    local snapshot_prefix="$1"

    [ -z "$PREFIXES" ] && [ -z "$snapshot_prefix" ] && return 0

    local i
    for i in $PREFIXES; do
        [ "$snapshot_prefix" = "$i" ] && return 0
    done

    return 1
}

# Returns 0 if it's a snapshot name that matches zfsnap's name pattern
# This also filters for any prefixes in effect
ValidSnapshotName() {
    IsSnapshot "$1" && return 1
    local snapshot_name="$1"

    TrimToPrefix "$snapshot_name" && local snapshot_prefix="$RETVAL" || return 1
    TrimToDate "$snapshot_name" && local snapshot_date="$RETVAL" || return 1
    TrimToTTL "$snapshot_name" && local snapshot_ttl="$RETVAL" || return 1

    local rebuilt_name="${snapshot_prefix}${snapshot_date}--${snapshot_ttl}"
    [ "$rebuilt_name" = "$snapshot_name" ] && return 0 || return 1
}

# Check validity of TTL
ValidTTL() {
    local ttl="$1"

    [ "$ttl" = '' ] && return 1
    [ "$ttl" = 'forever' ] && return 0

    while [ "$ttl" ]; do
        [ -z ${ttl##0*} ] && return 1 # leading zeros not accepted
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
        ;;
    'Linux')
        ;;
    'GNU/kFreeBSD')
        ;;
    'Darwin')
        ZFS_CMD='/usr/sbin/zfs'
        ZPOOL_CMD='/usr/sbin/zpool'
        ;;
    *)
        Fatal "Your OS isn't supported. However, not all hope is lost." \
              "zfsnap is very portable, and likely already runs on your system." \
              "Download the code and tests from https://github.com/zfsnap/zfsnap," \
              "let us know the results, and --- if all goes well --- we can add" \
              "your OS to the list of supported systems."
        ;;
esac
