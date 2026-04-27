# main loop; get options, process snapshot expiration/deletion
while [ -n "$1" ]; do
    OPTIND=1
    while getopts :DF:hnp:PrRsSvz OPT; do
        case "$OPT" in
            D) DELETE_ALL_SNAPSHOTS='true';;
            F) ValidTTL "$OPTARG" || Fatal "Invalid TTL: $OPTARG"
               [ "$OPTARG" = 'forever' ] && Fatal '-F does not accept the "forever" TTL'
               FORCE_AGE_TTL=$OPTARG
               FORCE_DELETE_BY_AGE='true'
               ;;
            h) Help;;
            n) DRY_RUN='true';;
            p) PREFIX=$OPTARG; PREFIXES="${PREFIXES:+$PREFIXES }$PREFIX";;
            P) PREFIX=''; PREFIXES='';;
            r) RECURSIVE='true';;
            R) RECURSIVE='false';;
            s) PopulateSkipPools 'resilver';;
            S) PopulateSkipPools 'scrub';;
            v) VERBOSE='true';;

            :) Fatal "Option -${OPTARG} requires an argument.";;
           \?) Fatal "Invalid option: -${OPTARG}.";;
        esac
    done

    # discard all arguments processed thus far
    shift $(($OPTIND - 1))

    # operate on pool/fs supplied
    if [ -n "$1" ]; then
        ZFS_SNAPSHOTS=`$ZFS_CMD list -H -o name -s name -t snapshot -r $1` >&2 || Fatal "'$1' does not exist!"
        ! SkipPool "$1" && shift && continue

        for SNAPSHOT in $ZFS_SNAPSHOTS; do
            if IsFalse "$RECURSIVE"; then
                TrimToFileSystem "$SNAPSHOT" && [ "$RETVAL" = "$1" ] || continue
            fi

            # gets and validates snapshot name
            TrimToSnapshotName "$SNAPSHOT" && SNAPSHOT_NAME=$RETVAL || continue

            if IsTrue $DELETE_ALL_SNAPSHOTS; then
                RM_SNAPSHOTS="$RM_SNAPSHOTS $SNAPSHOT"
            else
                TrimToDate "$SNAPSHOT_NAME" && CREATE_DATE=$RETVAL || continue
                if IsTrue "$FORCE_DELETE_BY_AGE"; then
                    DatePlusTTL "$CREATE_DATE" "$FORCE_AGE_TTL" && EXPIRATION_DATE=$RETVAL || continue
                else
                    TrimToTTL "$SNAPSHOT_NAME" && TTL=$RETVAL || continue
                    [ "$TTL" = 'forever' ] && continue
                    DatePlusTTL "$CREATE_DATE" "$TTL" && EXPIRATION_DATE=$RETVAL || continue
                fi

                CURRENT_DATE=${CURRENT_DATE:-`date "+$TIME_FORMAT"`}
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