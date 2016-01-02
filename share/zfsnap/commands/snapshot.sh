#!/bin/sh

# This file is licensed under the BSD-3-Clause license.
# See the AUTHORS and LICENSE files for more information.

PREFIX=''                           # Default prefix
PREFIXES=''                         # Needed for searching recent snapshots
SNAPSHOT_FREQ=''                    # Max allowed snapshot frequency

# FUNCTIONS
Help() {
    cat << EOF
${0##*/} v${VERSION}

Syntax:
${0##*/} snapshot [ options ] zpool/filesystem ...

OPTIONS:
  -a ttl       = How long the snapshot(s) should be kept (default: 1 month)
  -h           = Print this help and exit
  -f age       = Maximum frequency with which snapshots should be created. (Will
                 not create a new snapshot if an existing one is younger than
                 this limit.)
  -n           = Dry-run. Perform a trial run with no actions actually performed
  -p prefix    = Prefix to use when naming snapshots for all ZFS file
                 systems that follow this option
  -P           = Don't apply any prefix when naming snapshots for all ZFS
                 file systems that follow this option
  -r           = Create recursive snapshots for all ZFS file systems that
                 follow this option
  -R           = Create non-recursive snapshots for all ZFS file systems that
                 follow this option
  -s           = Skip pools that are resilvering
  -S           = Skip pools that are scrubbing
  -v           = Verbose output
  -z           = Round snapshot creation time down to 00 seconds

LINKS:
  website:          http://www.zfsnap.org
  repository:       https://github.com/zfsnap/zfsnap
  bug tracking:     https://github.com/zfsnap/zfsnap/issues

EOF
    Exit 0
}

# main loop; get options, process snapshot creation
while [ "$1" ]; do
    while getopts :a:hf:np:PrRsSvz OPT; do
        case "$OPT" in
            a) ValidTTL "$OPTARG" || Fatal "Invalid TTL: $OPTARG"
               TTL=$OPTARG
               ;;
            h) Help;;
            f) ValidTTL "$OPTARG" || Fatal "Invalid Duration: $OPTARG"
               SNAPSHOT_FREQ=$OPTARG
               ;;
            n) DRY_RUN='true';;
            p) PREFIX=$OPTARG;;
            P) PREFIX='';;
            r) ZOPT='-r';;
            R) ZOPT='';;
            s) PopulateSkipPools 'resilver';;
            S) PopulateSkipPools 'scrub';;
            v) VERBOSE='true';;
            z) TIME_FORMAT='%Y-%m-%d_%H.%M.00';;

            :) Fatal "Option -${OPTARG} requires an argument.";;
           \?) Fatal "Invalid option: -${OPTARG}.";;
        esac
    done

    # This must be set for "ValidPrefix" to work properly
    PREFIXES=$PREFIX

    # discard all arguments processed thus far
    shift $(($OPTIND - 1))

    # create snapshots
    if [ "$1" ]; then
        FSExists "$1" || Fatal "'$1' does not exist!"
        ! SkipPool "$1" && shift && continue

        CURRENT_DATE=${CURRENT_DATE:-`date "+$TIME_FORMAT"`}

        if [ -n "$SNAPSHOT_FREQ" ]; then
            # Check if there is already a recent snapshot within
            # $SNAPSHOT_FREQ of current date
            ZFS_SNAPSHOTS=`$ZFS_CMD list -H -o name -t snapshot -r $1` >&2 || Fatal "'$1' does not exist!"
            # Get the earliest date when the next snapshot should be created
            SNAPSHOT_ALLOWED_DATE=''
            for SNAPSHOT in $ZFS_SNAPSHOTS; do
                TrimToFileSystem "$SNAPSHOT" && [ "$RETVAL" = "$1" ] || continue

                # gets and validates snapshot name
                TrimToSnapshotName "$SNAPSHOT" && SNAPSHOT_NAME=$RETVAL || continue

                TrimToDate "$SNAPSHOT_NAME" && CREATE_DATE=$RETVAL || continue
                DatePlusTTL "$CREATE_DATE" "$SNAPSHOT_FREQ" && FREQ_EXPIRE_DATE=$RETVAL || continue
                if [ -z "$SNAPSHOT_ALLOWED_DATE" ] ||
                       GreaterDate $FREQ_EXPIRE_DATE $SNAPSHOT_ALLOWED_DATE; then
                    SNAPSHOT_ALLOWED_DATE=$FREQ_EXPIRE_DATE;
                fi
            done
            # If previous snapshot is too young, don't create a new
            # one
            if [ -n "$SNAPSHOT_ALLOWED_DATE" ] &&
                   GreaterDate $SNAPSHOT_ALLOWED_DATE $CURRENT_DATE; then
                shift && continue;
            fi
        fi

        ZFS_SNAPSHOT="$ZFS_CMD snapshot $ZOPT ${1}@${PREFIX}${CURRENT_DATE}--${TTL}"
        if IsFalse "$DRY_RUN"; then
            if $ZFS_SNAPSHOT >&2; then
                IsTrue $VERBOSE && printf '%s ... DONE\n' "$ZFS_SNAPSHOT"
            else
                IsTrue $VERBOSE && printf '%s ... FAIL\n' "$ZFS_SNAPSHOT"
            fi
        else
            printf '%s\n' "$ZFS_SNAPSHOT"
        fi

        shift
    fi
done
