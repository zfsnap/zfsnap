#!/bin/sh

# "THE BEER-WARE LICENSE":
# The zfSnap team wrote this file. As long as you retain this notice you
# can do whatever you want with this stuff. If we meet some day, and you think
# this stuff is worth it, you can buy me a beer in return.

# FUNCTIONS
Help() {
    cat << EOF
${0##*/} v${VERSION}

Syntax:
${0##*/} snapshot [ options ] zpool/filesystem ...

OPTIONS:
  -a ttl       = Set how long snapshot should be kept
  -e           = Return number of failed actions as exit code.
  -h           = Print this help and exit.
  -n           = Only show actions that would be performed
  -p prefix    = Use prefix for snapshots after this switch
  -P           = Don't use prefix for snapshots after this switch
  -r           = Create recursive snapshots for all zfs file systems that
                 follow this switch
  -R           = Create non-recursive snapshots for all zfs file systems that
                 follow this switch
  -s           = Don't do anything on pools running resilver
  -S           = Don't do anything on pools running scrub
  -v           = Verbose output
  -z           = Force new snapshots to have 00 seconds

LINKS:
  wiki:             https://github.com/graudeejs/zfSnap/wiki
  repository:       https://github.com/graudeejs/zfSnap
  bug tracking:     https://github.com/graudeejs/zfSnap/issues

EOF
    Exit 0
}

# MAIN
# main loop; get options, process snapshot creation
while [ "$1" ]; do
    while getopts :a:ehnp:PrRsSvz opt; do
        case "$opt" in
            a) ttl="$OPTARG"
               printf "%s" "$ttl" | grep -q -E -e "^[0-9]+$" && ttl=`Seconds2TTL "$ttl"`
               ValidTTL "$ttl" || Fatal "Invalid TTL: $ttl"
               ;;
            e) count_failures="true";;
            h) Help;;
            n) dry_run="true";;
            p) prefix="$OPTARG"; prefixes="${prefixes:+$prefixes|}$prefix";;
            P) prefix="";;
            r) zopt='-r';;
            R) zopt='';;
            s) PopulateSkipPools 'resilver';;
            S) PopulateSkipPools 'scrub';;
            v) verbose="true";;
            z) time_format='%Y-%m-%d_%H.%M.00';;

            :) Fatal "Option -$OPTARG requires an argument.";;
           \?) Fatal "Invalid option: -$OPTARG";;
        esac
    done

    # discard all arguments processed thus far
    shift $(($OPTIND - 1))

    # create snapshots
    if [ "$1" ]; then
        if SkipPool "$1"; then
            ntime="${ntime:-`date "+$time_format"`}"
            IsTrue $dry_run && zfs_list="${zfs_list:-`$zfs_cmd list -H -o name`}"

            zfs_snapshot="$zfs_cmd snapshot $zopt $1@${prefix}${ntime}--${ttl}"
            if IsFalse $dry_run; then
                if $zfs_snapshot > /dev/stderr; then
                    IsTrue $verbose && echo "$zfs_snapshot ... DONE"
                else
                    IsTrue $verbose && echo "$zfs_snapshot ... FAIL"
                    IsTrue $count_failures && failures=$(($failures + 1))
                fi
            else
                printf "%s\n" $zfs_list | grep -m 1 -q -E -e "^$1$" \
                    && echo "$zfs_snapshot" \
                    || Err "Looks like ZFS filesystem '$1' doesn't exist"
            fi
        fi
        shift
    fi
done
