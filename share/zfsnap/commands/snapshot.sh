#!/bin/sh

# This file is licensed under the BSD-3-Clause license.
# See the AUTHORS and LICENSE files for more information.

PREFIX=""                           # Default prefix

# FUNCTIONS
Help() {
    cat << EOF
${0##*/} v${VERSION}

Syntax:
${0##*/} snapshot [ options ] zpool/filesystem ...

OPTIONS:
  -a ttl       = Set how long snapshot should be kept
  -h           = Print this help and exit
  -n           = Dry‐run. Perform a trial run with no actions actually performed
  -p prefix    = Use prefix for snapshots after this switch
  -P           = Don't use prefix for snapshots after this switch
  -r           = Create recursive snapshots for all ZFS file systems that
                 follow this switch
  -R           = Create non-recursive snapshots for all ZFS file systems that
                 follow this switch
  -s           = Skip pools that are resilvering
  -S           = Skip pools that are scrubbing
  -v           = Verbose output
  -z           = Round snapshot creation time down to 00 seconds

LINKS:
  wiki:             https://github.com/zfsnap/zfsnap/wiki
  repository:       https://github.com/zfsnap/zfsnap
  bug tracking:     https://github.com/zfsnap/zfsnap/issues

EOF
    Exit 0
}

# main loop; get options, process snapshot creation
while [ "$1" ]; do
    while getopts :a:ehnp:PrRsSvz OPT; do
        case "$OPT" in
            a) ValidTTL "$OPTARG" || Fatal "Invalid TTL: $OPTARG"
               TTL="$OPTARG"
               ;;
            h) Help;;
            n) DRY_RUN="true";;
            p) PREFIX="$OPTARG"; PREFIXES="${PREFIXES:+$PREFIXES }$PREFIX";;
            P) PREFIX=''; PREFIXES='';;
            r) ZOPT='-r';;
            R) ZOPT='';;
            s) PopulateSkipPools 'resilver';;
            S) PopulateSkipPools 'scrub';;
            v) VERBOSE="true";;
            z) TIME_FORMAT='%Y-%m-%d_%H.%M.00';;

            :) Fatal "Option -$OPTARG requires an argument.";;
           \?) Fatal "Invalid option: -$OPTARG";;
        esac
    done

    # discard all arguments processed thus far
    shift $(($OPTIND - 1))

    # create snapshots
    if [ "$1" ]; then
        FSExists "$1" || Fatal "'$1' does not exist!"
        ! SkipPool "$1" && shift && continue

        CURRENT_DATE="${CURRENT_DATE:-`date "+$TIME_FORMAT"`}"

        ZFS_SNAPSHOT="$ZFS_CMD snapshot $ZOPT $1@${PREFIX}${CURRENT_DATE}--${TTL}"
        if IsFalse $DRY_RUN; then
            if $ZFS_SNAPSHOT > /dev/stderr; then
                IsTrue $VERBOSE && printf "%s ... DONE\n" "$ZFS_SNAPSHOT"
            else
                IsTrue $VERBOSE && printf "%s ... FAIL\n" "$ZFS_SNAPSHOT"
            fi
        else
            printf '%s\n' "$ZFS_SNAPSHOT"
        fi

        shift
    fi
done
