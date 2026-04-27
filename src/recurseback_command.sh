# main loop; get options, process snapshot creation
while [ -n "$1" ]; do
    OPTIND=1
    while getopts :d:fhnrRv OPT; do
        case "$OPT" in
            d) DEPTH="-d $OPTARG";;
            f) IsFalse "$FORCE" && ROLLBACK_OPT="${ROLLBACK_OPT} -f"
               FORCE='true';;
            h) Help;;
            n) DRY_RUN='true';;
            r) ROLLBACK_OPT='-r'
               IsTrue "$FORCE" && ROLLBACK_OPT='-r -f';;
            R) ROLLBACK_OPT='-R'
               IsTrue "$FORCE" && ROLLBACK_OPT='-R -f';;
            v) VERBOSE='true';;

            :) Fatal "Option -${OPTARG} requires an argument.";;
           \?) Fatal "Invalid option: -${OPTARG}.";;
        esac
    done

    # discard all arguments processed thus far
    shift $(($OPTIND - 1))

    # rollback
    if [ -n "$1" ]; then
        IsSnapshot "$1" || Fatal "You must provide a snapshot to rollback to."
        $ZFS_CMD list -H -t snapshot -o name -s name "$1" > /dev/null || Fatal "'$1' does not exist!"
        TrimToFileSystem "$1" && FS_NAME=$RETVAL
        SNAPSHOT_NAME=${1##${FS_NAME}@}

        ZFS_DATASETS=`$ZFS_CMD list -H -o name $DEPTH -t filesystem,volume -r $FS_NAME` >&2 || Fatal "'$FS_NAME' does not exist!"

        if IsTrue "$VERBOSE"; then
            INTENT='would' && IsFalse "$DRY_RUN" && INTENT='will'
            for DATASET in $ZFS_DATASETS; do
                printf '%s rollback to %s@%s\n' "$INTENT" "${DATASET}" "${SNAPSHOT_NAME}"
            done

            # print estimate of data to be freed
            BYTES_FREE=0
            for FREE in `$ZFS_CMD list -Hp $DEPTH -o written@${SNAPSHOT_NAME} -r ${FS_NAME}`; do
                IsInt "$FREE" && BYTES_FREE=$(($BYTES_FREE + $FREE))
            done

            BytesToHuman "$BYTES_FREE" && HUMAN_UNITS=$RETVAL
            printf '%s recover %s\n' "$INTENT" "$HUMAN_UNITS"
        fi

        if IsFalse "$DRY_RUN"; then
            for DATASET in $ZFS_DATASETS; do
                ZFS_ROLLBACK="$ZFS_CMD rollback $ROLLBACK_OPT ${DATASET}@${SNAPSHOT_NAME}"
                if ! $ZFS_ROLLBACK >&2; then
                    printf 'FAIL ... %s\n' "$ZFS_ROLLBACK"
                fi
            done
        fi

        ZFS_DATASETS=''
        shift
    fi
done
