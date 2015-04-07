#!/bin/sh

# This file is licensed under the BSD-3-Clause license.
# See the AUTHORS and LICENSE files for more information.
#
# website:          http://www.zfsnap.org
# repository:       https://github.com/zfsnap/zfsnap
# bug tracking:     https://github.com/zfsnap/zfsnap/issues

# Put zsh in POSIX mode
[ -n "${ZSH_VERSION-}" ] && emulate -R sh

readonly VERSION='2.0.0.beta2'

# COMMANDS
ZFS_CMD='/sbin/zfs'
ZPOOL_CMD='/sbin/zpool'

# VARIABLES
TTL='1m'                            # default snapshot TTL
VERBOSE='false'                     # Verbose output?
DRY_RUN='false'                     # Dry run?
POOLS=''                            # List of pools
FS_LIST=''                          # List of all ZFS filesystems
SKIP_POOLS=''                       # List of pools to skip

readonly OS=`uname`
readonly DATE_PATTERN='[12][90][0-9][0-9]-[01][0-9]-[0-3][0-9]_[0-2][0-9].[0-5][0-9].[0-5][0-9]'
TEST_MODE=${TEST_MODE:-false}       # When set to "true", Exit won't really exit
TIME_FORMAT='%Y-%m-%d_%H.%M.%S'     # date/time format for snapshot creation and comparison
RETVAL=''                           # used by functions so we can avoid spawning subshells

## HELPER FUNCTIONS
Err() {
    printf '%s\n' "ERROR: $*" >&2
}
Exit() {
    IsTrue "$TEST_MODE" || exit $1
}
Fatal() {
    printf '%s\n' "FATAL: $*" >&2
    exit 1
}
Note() {
    printf '%s\n' "NOTE: $*" >&2
}
Warn() {
    printf '%s\n' "WARNING: $*" >&2
}

# Returns 0 if argument is "false"
IsFalse() {
    IsTrue "$1" && return 1 || return 0
}
# Returns 0 if argument is "true"
IsTrue() {
    case "$1" in
        true)  return 0 ;;
        false) return 1 ;;
        *)     Fatal "'$1' must be true or false." ;;
    esac
}

## ZFSNAP FUNCTIONS

# Convert bytes to human readable format, to a maximum of one decimal place
#   This approach, while admittedly a bit insane, supports shells which don't
#   have 64-bit integers (mksh, I'm looking at you). As an added plus, this
#   approach handles numbers larger than 64-bit signed integers (~16 EiB),
#   though that's not exactly a terribly likely scenario...
#
#   The premise is that floating points are a matter of where the decimal is. By
#   padding/stripping everything to 9 digits in length (the max safe length for
#   32-bit), then enough precision is available to get a reasonably accurate
#   answer. Possible because the answer's max precision is to one decimal place.
#
#   This approach is not perfect and occasionally will be off by one in the
#   right-most digit. This is an acceptable trade-off IMO, as human readable is
#   already inherently "wrong" by virtue of rounding. If the user wants uber
#   precision, ZFS can tell them the Bytes directly.
# Accepts 1 integer
# Retvals human readable size: e.g. 3.2G
BytesToHuman() {
    local num="$1"
    local answer=''
    local t_dels=0 # number of thousands delimiters

    # must be an integer
    ! IsInt "$num" && RETVAL='' && return 1

    # Bytes can skip the abuses which are to follow
    if [ ${#num} -le 4 ] && [ $num -lt 1024 ]; then
        answer=$num
    else
        local magic=0 # denominator to compensate for base-8 vs base-10 math
        local valley8v10='false' # in the valley of base-8 vs base-10 (e.g. 1022KiB)
        t_dels=$(( (${#num} - 1) / 3 ))

        while true; do
            case $t_dels in
                # numbers derived by taking the first 6 digits of 1024^${t_dels}
                1) magic=102400;; 2) magic=104857;; 3) magic=107374;; # 1) KiB 2) MiB 3) GiB
                4) magic=109951;; 5) magic=112589;; 6) magic=115292;; # 4) TiB 5) PiB 6) EiB
            esac
            # check for the awkward valley of base-8 vs base-10 (e.g. 1010MB)
            IsTrue "$valley8v10" || [ ${magic} -eq 102400 ] && break
            [ $(( ${#num} % 3 )) -ne 1 ] || [ ${num%${num#??????}} -ge $magic ] && break

            valley8v10='true'
            t_dels=$(( $t_dels - 1 ))
        done

        # strip $magic to account for length of $num
        [ $(( ${#num} % 3 )) -eq 2 ] && magic=${magic%?}
        [ $(( ${#num} % 3 )) -eq 0 ] && magic=${magic%??}

        # pad/strip to 9 characters - the longest safe length
        while [ ${#num} -lt 9 ]; do
            num="${num}0"
        done
        num=${num%${num#?????????}}

        # calculate answer; format (if needed) to strip excess and insert decimal
        local new_num=$(( $num / $magic ))
        if IsTrue "$valley8v10"; then
            answer=${new_num}
        else
            answer=${new_num%???}
            if [ ${#answer} -lt 3 ]; then # if we have sufficient-ish precision to use a decimal
                local last_three=${new_num#${answer}}
                # add decimal only if it won't be .0
                [ ${last_three%??} -ne 0 ] && answer="${answer}.${last_three%??}"
            fi
        fi
    fi

    # select appropriate unit
    local answer_unit
    for answer_unit in '' K M G T P E; do
        [ $t_dels -eq 0 ] && break
        t_dels=$(( $t_dels - 1 ))
    done

    RETVAL="${answer}${answer_unit}" && return 0
}

# Mathmatically add a TTL to a date
#   When a TTL is added to a date, each field is added independently,
#   any month overflows are carried into years, and then all overflows
#   are carried normally from right to left (e.g. 2009-02-27 plus 1m3d
#   results in 2009-03-30 rather than 2009-04-02).
#
#   Corner case: adding 1m to 2009-10-31 will result in 2009-12-01
#   rather than 2009-11-30. Because there are only 30 days in November,
#   precisely one month after October 31st is ambigious. This returns
#   the more conservative (later) option.
# Accepts a zfsnap date and a TTL
# Retvals a zfsnap date
DatePlusTTL() {
    ValidDate "$1" && local orig_date="$1" || { RETVAL=''; return 1; }
    local ttl="$2"

    # break date into components; strip leading zeros
    local y="${orig_date%%-*}" && y=${y#0} && orig_date=${orig_date#*-}
    local m="${orig_date%%-*}" && m=${m#0} && orig_date=${orig_date#*-}
    local d="${orig_date%%_*}" && d=${d#0} && orig_date=${orig_date#*_}
    local h="${orig_date%%.*}" && h=${h#0} && orig_date=${orig_date#*.}
    local M="${orig_date%%.*}" && M=${M#0} && orig_date=${orig_date#*.}
    local s="${orig_date}" && s=${s#0}

    while [ -n "$ttl" ]; do
        case "$ttl" in
            *y*) y=$((${ttl%%y*} + $y)); ttl=${ttl#*y} ;;
            *m*) m=$((${ttl%%m*} + $m)); ttl=${ttl#*m} ;;
            *w*) d=$(((${ttl%%w*} * 7) + $d)); ttl=${ttl#*w} ;;
            *d*) d=$((${ttl%%d*} + $d)); ttl=${ttl#*d} ;;
            *h*) h=$((${ttl%%h*} + $h)); ttl=${ttl#*h} ;;
            *M*) M=$((${ttl%%M*} + $M)); ttl=${ttl#*M} ;;
             *s) s=$((${ttl%%s*} + $s)); ttl=${ttl#*s} ;;
              *) Warn "Invalid TTL '$ttl' in DatePlusTTL."; RETVAL=''; return 1 ;;
        esac
    done

    # roll seconds into minutes into hours into days
    [ $s -ge 60 ] && M=$(($M + ($s / 60))) && s=$(($s % 60))
    [ $M -ge 60 ] && h=$(($h + ($M / 60))) && M=$(($M % 60))
    [ $h -ge 24 ] && d=$(($d + ($h / 24))) && h=$(($h % 24))

    # days, months, years
    while true; do
        # roll months into years
        [ $m -gt 12 ] && y=$(($y + ($m / 12))) && m=$(($m % 12))
        [ $m -eq 0 ] && m=1

        # roll days into months
        local month_lengths='31 28 31 30 31 30 31 31 30 31 30 31'
        local m_num=0
        local m_length
        for m_length in $month_lengths; do
            m_num=$(($m_num + 1))

            # skip if we're not to current month yet
            [ $m -gt $m_num ] && continue

            # adjust if february in a leap year
            [ $m_num -eq 2 ] && IsLeapYear "$y" && m_length=29

            [ $d -le $m_length ] && break 2

            d=$(($d - $m_length)) && m=$(($m + 1))
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
# returns 2 if input is invalid
GreaterDate() {
    ValidDate "$1" && local date1="$1" || return 2
    ValidDate "$2" && local date2="$2" || return 2

    while [ -n "$date1" ]; do
        # get the first field and strip off any leading zeros
        local field1=${date1%%[-_.]*} && field1=${field1#0}
        local field2=${date2%%[-_.]*} && field2=${field2#0}

        [ "$field1" -gt "$field2" ] && return 0
        [ "$field1" -eq "$field2" ] || return 1

        # if no separators left (seconds), bail
        [ -z "${date1%%*[-_.]*}" ] || break

        date1=${date1#*[-_.]} && date2=${date2#*[-_.]}
    done

    return 0
}

# Returns 0 if filesystem exists
FSExists() {
    FS_LIST=${FS_LIST:-`$ZFS_CMD list -H -o name`}

    local i
    for i in $FS_LIST; do
        [ "$1" = "$i" ] && return 0
    done

    return 1
}

# Returns 0 if argument is an integer
IsInt() {
    [ -z "${1##*[!0-9]*}" ] && return 1 || return 0
}

# Accepts one integer
# Returns 0 if supplied year is a leap year
IsLeapYear() {
    local year="$1"
    IsInt "$year" || return 1

    [ $(($year % 400)) -eq 0 ] && return 0
    [ $(($year % 100)) -eq 0 ] && return 1
    [ $(($year % 4)) -eq 0 ] && return 0

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
    POOLS=${POOLS:-`$ZPOOL_CMD list -H -o name`}

    local i
    for i in $POOLS; do
        [ "$1" = "$i" ] && return 0
    done

    return 1
}

# Populates the $SKIP_POOLS global variable; does not return anything
PopulateSkipPools() {
    [ -z "$1" ] && Fatal 'PopulateSkipPools requires an argument!'
    POOLS=${POOLS:-`$ZPOOL_CMD list -H -o name`}

    local i
    for i in $POOLS; do
        ZSTATUS=`"$ZPOOL_CMD" status "$i"`
        [ -z "${ZSTATUS##*$1 in progress*}" ] && SKIP_POOLS="${SKIP_POOLS:+$SKIP_POOLS }$i"
    done
}

# Removes ZFS snapshot
RmZfsSnapshot() {
    SkipPool "$1" || return 1

    local zfs_destroy="$ZFS_CMD destroy $*"

    # hardening: make really, really sure we are deleting a snapshot
    if IsSnapshot "$1"; then
        if IsFalse "$DRY_RUN"; then
            if $zfs_destroy >&2; then
                IsTrue "$VERBOSE" && printf '%s ... DONE\n' "$zfs_destroy"
            else
                IsTrue "$VERBOSE" && printf '%s ... FAIL\n' "$zfs_destroy"
            fi
        else
            printf '%s\n' "$zfs_destroy"
        fi
    else
        Fatal 'Trying to delete ZFS pool or filesystem? WTF?' \
              'This is bug, and we definitely do not want that.' \
              'Please report it to https://github.com/zfsnap/zfsnap/issues' \
              'Do not panic, as nothing was deleted. :-)'
    fi
}

# Returns 1 if ZFS operations on given pool should be skipped.
# This function's name implies the opposite of what it does. It
# should be renamed, but I can't come up with anything intuitive and short.
SkipPool() {
    local i
    for i in $SKIP_POOLS; do
        if TrimToPool "$1" && [ "$RETVAL" = "$i" ]; then
            IsTrue "$VERBOSE" && Note "No actions will be performed on '$1'. Resilver or Scrub is running on pool."
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
    [ -z "${snapshot_name##*$DATE_PATTERN*}" ] || { RETVAL=''; return 1; }

    local pre_date="${snapshot_name%$DATE_PATTERN*}"
    local post_date="${snapshot_name##*$DATE_PATTERN}"

    local snapshot_date="${snapshot_name##$pre_date}"
    snapshot_date=${snapshot_date%%$post_date}

    if [ -z "${snapshot_date##$DATE_PATTERN}" ]; then
        RETVAL=$snapshot_date && return 0
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
        RETVAL=$file_system && return 0
    else
        RETVAL='' && return 1
    fi
}

# Retvals the pool name (anything before the first '/' or '@')
# If no valid pool is found, it will return 1.
TrimToPool() {
    local pool_name="${1%%[/@]*}"

    if PoolExists "$pool_name"; then
        RETVAL=$pool_name && return 0
    else
        RETVAL='' && return 1
    fi
}

# Retvals the prefix in a snapshot name (anything prior to the "snapshot date")
# If no valid "snapshot date" or prefix is found, it will return 1.
TrimToPrefix() {
    local snapshot_name="$1"

    # make sure it contains a date
    [ -z "${snapshot_name##*$DATE_PATTERN*}" ] || { RETVAL=''; return 1; }

    local snapshot_prefix="${snapshot_name%$DATE_PATTERN*}"
    if ValidPrefix "$snapshot_prefix"; then
        RETVAL=$snapshot_prefix && return 0
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
        RETVAL=$snapshot_name && return 0
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
        RETVAL=$ttl && return 0
    else
        RETVAL='' && return 1
    fi
}

# Check validity of a zfsnap date
ValidDate() {
    [ -z "$1" ] && return 1
    [ -z "${1##$DATE_PATTERN}" ] && return 0 || return 1
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

    [ -z "$ttl" ] && return 1
    [ "$ttl" = 'forever' ] && return 0

    while [ -n "$ttl" ]; do
        [ -z "${ttl##0*}" ] && return 1 # leading zeros not accepted
        case "$ttl" in
            *y*) IsInt "${ttl%y*}" && ttl=${ttl##*y} || return 1 ;;
            *m*) IsInt "${ttl%m*}" && ttl=${ttl##*m} || return 1 ;;
            *w*) IsInt "${ttl%w*}" && ttl=${ttl##*w} || return 1 ;;
            *d*) IsInt "${ttl%d*}" && ttl=${ttl##*d} || return 1 ;;
            *h*) IsInt "${ttl%h*}" && ttl=${ttl##*h} || return 1 ;;
            *M*) IsInt "${ttl%M*}" && ttl=${ttl##*M} || return 1 ;;
             *s) IsInt "${ttl%s*}" && ttl=${ttl##*s} || return 1 ;;
              *) return 1 ;;
        esac
    done

    return 0
}

## MAIN
case "$OS" in
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
        Fatal 'Your OS is not supported. However, not all hope is lost.' \
              'zfsnap is very portable, and likely already runs on your system.' \
              'Download the code and tests from https://github.com/zfsnap/zfsnap,' \
              'let us know the results, and---if all goes well---we can add' \
              'your OS to the list of supported systems.'
        ;;
esac
