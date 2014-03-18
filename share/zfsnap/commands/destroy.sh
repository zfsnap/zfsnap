#!/bin/sh

# This file is licensed under the BSD-3-Clause license.
# See the AUTHORS and LICENSE files for more information.

DELETE_ALL_SNAPSHOTS="false"        # Should all snapshots be deleted, regardless of TTL
RM_SNAPSHOTS=''                     # List of specific snapshots to delete
FORCE_DELETE_SNAPSHOTS_AGE=-1       # Delete snapshots older than x seconds. -1 means NO
RECURSIVE="false"
PREFIXES=""                         # List of prefixes
CURRENT_TIME=`date +%s`

# FUNCTIONS
Help() {
    cat << EOF
${0##*/} v${VERSION}

Syntax:
${0##*/} destroy [ options ] zpool/filesystem ...

OPTIONS:
  -D           = Delete all zfsnap snapshots of pools specified (ignore ttl)
  -e           = Return number of failed actions as exit code.
  -F age       = Force delete all snapshots exceeding age
  -h           = Print this help and exit.
  -n           = Only show actions that would be performed
  -p prefix    = Use prefix for snapshots after this switch
  -P           = Don't use prefixes for snapshots after this switch
  -r           = Operate recursively on all ZFS file systems after this switch.
  -R           = Do not operate recursively on all ZFS file systems after this switch.
  -s           = Don't do anything on pools running resilver
  -S           = Don't do anything on pools running scrub
  -v           = Verbose output

LINKS:
  wiki:             https://github.com/zfsnap/zfsnap/wiki
  repository:       https://github.com/zfsnap/zfsnap
  bug tracking:     https://github.com/zfsnap/zfsnap/issues

EOF
    Exit 0
}

# MAIN
# main loop; get options, process snapshot creation
while [ "$1" ]; do
    while getopts :DeF:hnp:PrRsSvz OPT; do
        case "$OPT" in
            D) DELETE_ALL_SNAPSHOTS="true";;
            F) TTL2Seconds "$OPTARG" && FORCE_DELETE_SNAPSHOTS_AGE="$RETVAL";;
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

    # delete snapshots
    if [ "$1" ]; then
        ZFS_SNAPSHOTS=`$ZFS_CMD list -H -o name -t snapshot -r $1` > /dev/stderr || Fatal "'$1' does not exist!"

        for SNAPSHOT in $ZFS_SNAPSHOTS; do
            if IsFalse $RECURSIVE; then
                TrimToFileSystem "$SNAPSHOT" && [ "$RETVAL" = "$1" ] || continue
            fi
            TrimToSnapshotName "$SNAPSHOT" || continue
            ZFSNAP_SNAPSHOTS="$ZFSNAP_SNAPSHOTS $SNAPSHOT"
        done

        if IsTrue $DELETE_ALL_SNAPSHOTS; then
            RM_SNAPSHOTS="$ZFSNAP_SNAPSHOTS"
        else
            # TODO, create_time could be cached
            for I in $ZFSNAP_SNAPSHOTS; do
                TrimToSnapshotName "$I" && SNAPSHOT_NAME="$RETVAL" || continue
                TrimToDate "$SNAPSHOT_NAME" && CREATE_DATE="$RETVAL" || continue
                CREATE_TIME=`Date2Timestamp "$CREATE_DATE"`

                if [ "$FORCE_DELETE_SNAPSHOTS_AGE" -ne -1 ]; then
                    if [ $CURRENT_TIME -gt $(($CREATE_TIME + $FORCE_DELETE_SNAPSHOTS_AGE)) ]; then
                        RM_SNAPSHOTS="$RM_SNAPSHOTS $I"
                    fi
                else
                    TrimToTTL "$SNAPSHOT_NAME" && TTL="$RETVAL" || continue

                    TTL2Seconds "$TTL" && STAY_TIME="$RETVAL"
                    if [ $CURRENT_TIME -gt $(($CREATE_TIME + $STAY_TIME)) ]; then
                        RM_SNAPSHOTS="$RM_SNAPSHOTS $I"
                    fi
                fi
            done
        fi

        for I in $RM_SNAPSHOTS; do
            RmZfsSnapshot "$I"
        done
        RM_SNAPSHOTS=''

        shift
    fi
done
