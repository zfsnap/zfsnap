
# main loop; get options, process snapshot creation
while [ "$1" ]; do
    OPTIND=1
    while getopts :a:hnp:PrRsSvz OPT; do
        case "$OPT" in
            a) ValidTTL "$OPTARG" || Fatal "Invalid TTL: $OPTARG"
               TTL=$OPTARG
               ;;
            h) Help;;
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

    # discard all arguments processed thus far
    shift $(($OPTIND - 1))

    # create snapshots
    if [ "$1" ]; then
        FSExists "$1" || Fatal "'$1' does not exist!"
        ! SkipPool "$1" && shift && continue

        CURRENT_DATE=${CURRENT_DATE:-`date "+$TIME_FORMAT"`}

        [ -z ${PREFIX} ] || PREFIX=${PREFIX%%[-]}-

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
