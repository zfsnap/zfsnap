#!/bin/sh

# This file is licensed under the BSD-3-Clause license.
# See the AUTHORS and LICENSE files for more information.

# TODO: rename to something other than "promote" since that is alreay a ZFS concept.

RECURSIVE='false'
PREFIXES=''                         # List of prefixes to promote from
PROMOTION_PREFIX=''                 # Prefix to promote to
MIN_PROMOTION_AGE=''                # Min age for promotion
CANDIDATE_SNAPSHOT=''               # Current candidate snapshot for promotion

# FUNCTIONS
Help() {
    cat << EOF
${0##*/} v${VERSION}

Syntax:
${0##*/} promote [ options ] -p from_prefix -t to_prefix -A min_age -a new_ttl zpool/filesystem ...

OPTIONS:

  -a new_ttl   = How long the promoted snapshot(s) should be kept (required)
  -A min_age   = Minimum age for a snapshot to be considered for promotion (required)
  -h           = Print this help and exit
  -n           = Dry-run. Perform a trial run with no actions actually performed
  -p prefix    = Prefix to promote snapshots from. Must be specified at least once.
  -r           = Operate recursively on all ZFS file systems after this option
  -R           = Do not operate recursively on all ZFS file systems after this option
  -s           = Skip pools that are resilvering
  -S           = Skip pools that are scrubbing
  -t prefix    = Prefix to promote snapshots to. Must be specified exactly once.
  -v           = Verbose output

LINKS:
  website:          http://www.zfsnap.org
  repository:       https://github.com/zfsnap/zfsnap
  bug tracking:     https://github.com/zfsnap/zfsnap/issues

EOF
    Exit 0
}

# main loop; get options, process snapshot expiration/deletion
while [ -n "$1" ]; do
    while getopts :a:A:hnp:rRsSt:vz OPT; do
        case "$OPT" in
            a) ValidTTL "$OPTARG" || Fatal "Invalid TTL: $OPTARG"
               TTL=$OPTARG
               ;;
            A) ValidTTL "$OPTARG" || Fatal "Invalid age: $OPTARG"
               MIN_PROMOTION_AGE=$OPTARG
               ;;
            h) Help;;
            n) DRY_RUN='true';;
            p) PREFIX=$OPTARG; PREFIXES="${PREFIXES:+$PREFIXES }$PREFIX";;
            r) ZOPT='-r';;
            R) ZOPT='';;
            s) PopulateSkipPools 'resilver';;
            S) PopulateSkipPools 'scrub';;
            t) PROMOTION_PREFIX=$OPTARG;;
            v) VERBOSE='true';;

            :) Fatal "Option -${OPTARG} requires an argument.";;
            \?) Fatal "Invalid option: -${OPTARG}.";;
        esac
    done

    # discard all arguments processed thus far
    shift $(($OPTIND - 1))

    [ -n "$TTL" ] || Fatal "Option -a is required"
    [ -n "$MIN_PROMOTION_AGE" ] || Fatal "Option -A is required"
    [ -n "$PREFIXES" ] || Fatal "Option -p is required"
    [ -n "$PROMOTION_PREFIX" ] || Fatal "Option -t is required"

    # operate on pool/fs supplied
    if [ -n "$1" ]; then
        ZFS_SNAPSHOTS=`$ZFS_CMD list -H -o name -t snapshot -r $1` >&2 || Fatal "'$1' does not exist!"
        ! SkipPool "$1" && shift && continue

        for SNAPSHOT in $ZFS_SNAPSHOTS; do

            # Even if $RECURSIVE is True, we still only want to look
            # at the root because "zfs rename -r" will handle the
            # recursion.
            TrimToFileSystem "$SNAPSHOT" && [ "$RETVAL" = "$1" ] || continue

            # gets and validates snapshot name
            TrimToSnapshotName "$SNAPSHOT" && SNAPSHOT_NAME=$RETVAL || continue

            # Skip snapshots younger than specified age
            TrimToDate "$SNAPSHOT_NAME" && CREATE_DATE=$RETVAL || continue
            DatePlusTTL "$CREATE_DATE" "$MIN_PROMOTION_AGE" && PROMOTION_DATE=$RETVAL || continue
            CURRENT_DATE=${CURRENT_DATE:-`date "+$TIME_FORMAT"`}
            GreaterDate "$CURRENT_DATE" "$PROMOTION_DATE" || continue

            # Replace candidate if it is younger than the candidate
            if [ -z "$CANDIDATE_SNAPSHOT" ]; then
                CANDIDATE_SNAPSHOT="$SNAPSHOT"
                TrimToDate "$CANDIDATE_SNAPSHOT" && CANDIDATE_DATE=$RETVAL || Fatal "Invalid snap: $SNAPSHOT"
            else
                TrimToDate "$SNAPSHOT" && SNAPDATE=$RETVAL || continue
                if GreaterDate "$SNAPDATE" "$CANDIDATE_DATE"; then
                    CANDIDATE_SNAPSHOT="$SNAPSHOT"
                    TrimToDate "$CANDIDATE_SNAPSHOT" && CANDIDATE_DATE=$RETVAL || Fatal "Invalid snap: $SNAPSHOT"
                fi
            fi
        done

        if [ -n "$CANDIDATE_SNAPSHOT" ]; then
            NEWNAME="${1}@${PROMOTION_PREFIX}${CANDIDATE_DATE}--${TTL}"
            ZFS_RENAME="$ZFS_CMD rename $ZOPT $CANDIDATE_SNAPSHOT $NEWNAME"
            if IsFalse "$DRY_RUN"; then
                if $ZFS_RENAME >&2; then
                    IsTrue $VERBOSE && printf '%s ... DONE\n' "$ZFS_RENAME"
                else
                    IsTrue $VERBOSE && printf '%s ... FAIL\n' "$ZFS_RENAME"
                fi
            else
                printf '%s\n' "$ZFS_RENAME"
            fi
        fi
        CANDIDATE_SNAPSHOT=''

        shift
    fi
done
