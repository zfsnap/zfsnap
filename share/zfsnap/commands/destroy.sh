#!/bin/sh

# This file is licensed under the BSD-3-Clause license.
# See the AUTHORS and LICENSE files for more information.

DELETE_ALL_SNAPSHOTS="false"        # Should all snapshots be deleted, regardless of TTL
RM_SNAPSHOTS=''                     # List of specific snapshots to delete
FORCE_DELETE_BY_AGE='false'         # Ignore TTL expiration and delete if older than "AGE" (in TTL format).
FORCE_AGE_TTL=''                    # Used to store "age" TTL if FORCE_DELETE_BY_AGE is set.
RECURSIVE="false"
PREFIXES=""                         # List of prefixes

# FUNCTIONS
Help() {
    cat << EOF
${0##*/} v${VERSION}

Syntax:
${0##*/} destroy [ options ] zpool/filesystem ...

OPTIONS:
  -D           = Delete *all* zfsnap snapshots of pools specified
  -F age       = Force delete all snapshots exceeding age (rather than TTL expiration)
  -h           = Print this help and exit
  -n           = Dry‐run. Perform a trial run with no actions actually performed
  -p prefix    = Use prefix for snapshots after this switch
  -P           = Don't use prefixes for snapshots after this switch
  -r           = Operate recursively on all ZFS file systems after this switch
  -R           = Do not operate recursively on all ZFS file systems after this switch
  -s           = Skip pools that are resilvering
  -S           = Skip pools that are scrubbing
  -v           = Verbose output

LINKS:
  wiki:             https://github.com/zfsnap/zfsnap/wiki
  repository:       https://github.com/zfsnap/zfsnap
  bug tracking:     https://github.com/zfsnap/zfsnap/issues

EOF
    Exit 0
}

# main loop; get options, process snapshot expiration/deletion
while [ "$1" ]; do
    while getopts :DeF:hnp:PrRsSvz OPT; do
        case "$OPT" in
            D) DELETE_ALL_SNAPSHOTS="true";;
            F) ValidTTL "$OPTARG" || Fatal "Invalid TTL: $OPTARG"
               [ "$OPTARG" = 'forever' ] && Fatal "-F does not accept the 'forever' TTL"
               FORCE_AGE_TTL="$OPTARG"
               FORCE_DELETE_BY_AGE="true"
               ;;
            h) Help;;
            n) DRY_RUN="true";;
            p) PREFIX="$OPTARG"; PREFIXES="${PREFIXES:+$PREFIXES }$PREFIX";;
            P) PREFIX=''; PREFIXES='';;
            r) RECURSIVE='true';;
            R) RECURSIVE='false';;
            s) PopulateSkipPools 'resilver';;
            S) PopulateSkipPools 'scrub';;
            v) VERBOSE="true";;

            :) Fatal "Option -$OPTARG requires an argument.";;
           \?) Fatal "Invalid option: -$OPTARG";;
        esac
    done

    # discard all arguments processed thus far
    shift $(($OPTIND - 1))

    # operate on pool/fs supplied
    if [ "$1" ]; then
        ZFS_SNAPSHOTS=`$ZFS_CMD list -H -o name -t snapshot -r $1` > /dev/stderr || Fatal "'$1' does not exist!"
        ! SkipPool "$1" && shift && continue

        for SNAPSHOT in $ZFS_SNAPSHOTS; do
            if IsFalse $RECURSIVE; then
                TrimToFileSystem "$SNAPSHOT" && [ "$RETVAL" = "$1" ] || continue
            fi

            # gets and validates snapshot name
            TrimToSnapshotName "$SNAPSHOT" && SNAPSHOT_NAME="$RETVAL" || continue

            if IsTrue $DELETE_ALL_SNAPSHOTS; then
                RM_SNAPSHOTS="$RM_SNAPSHOTS $SNAPSHOT"
            else
                TrimToDate "$SNAPSHOT_NAME" && CREATE_DATE="$RETVAL" || continue
                if IsTrue "$FORCE_DELETE_BY_AGE"; then
                    DatePlusTTL "$CREATE_DATE" "$FORCE_AGE_TTL" && EXPIRATION_DATE="$RETVAL" || continue
                else
                    TrimToTTL "$SNAPSHOT_NAME" && TTL="$RETVAL" || continue
                    [ "$TTL" = 'forever' ] && continue
                    DatePlusTTL "$CREATE_DATE" "$TTL" && EXPIRATION_DATE="$RETVAL" || continue
                fi

                CURRENT_DATE="${CURRENT_DATE:-`date "+$TIME_FORMAT"`}"
                if GreaterDate "$CURRENT_DATE" "$EXPIRATION_DATE"; then
                    RM_SNAPSHOTS="$RM_SNAPSHOTS $SNAPSHOT"
                fi
            fi
        done

        for I in $RM_SNAPSHOTS; do
            RmZfsSnapshot "$I"
        done
        RM_SNAPSHOTS=''

        shift
    fi
done
