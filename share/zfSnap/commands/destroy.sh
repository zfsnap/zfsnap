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
${0##*/} destroy [ options ] zpool/filesystem ...

OPTIONS:
  -D           = Delete all zfSnap snapshots of pools specified (ignore ttl)
  -e           = Return number of failed actions as exit code.
  -F age       = Force delete all snapshots exceeding age
  -h           = Print this help and exit.
  -n           = Only show actions that would be performed
  -p prefix    = Use prefix for snapshots after this switch
  -s           = Don't do anything on pools running resilver
  -S           = Don't do anything on pools running scrub
  -v           = Verbose output

LINKS:
  wiki:             https://github.com/graudeejs/zfSnap/wiki
  repository:       https://github.com/graudeejs/zfSnap
  bug tracking:     https://github.com/graudeejs/zfSnap/issues

EOF
    Exit 0
}

# MAIN
###########
delete_snapshots="true"
delete_all_snapshots="false"        # List of specific snapshots to delete

# main loop; get options, process snapshot creation
while [ "$1" ]; do
    while getopts :DeF:hnp:PrRsSvz opt; do
        case "$opt" in
            D) delete_all_snapshots="true";;
            e) count_failures="true";;
            F) force_delete_snapshots_age=`TTL2Seconds "$OPTARG"`;;
            h) Help;;
            n) dry_run="true";;
            p) prefix="$OPTARG"; prefixes="${prefixes:+$prefixes|}$prefix";;
            s) PopulateSkipPools 'resilver';;
            S) PopulateSkipPools 'scrub';;
            v) verbose="true";;

            :) Fatal "Option -$OPTARG requires an argument.";;
           \?) Fatal "Invalid option: -$OPTARG";;
        esac
    done

    # discard all arguments processed thus far
    shift $(($OPTIND - 1))

    # delete snapshots
    if [ "$1" ]; then
        if IsTrue $delete_snapshots || [ $force_delete_snapshots_age -ne -1 ]; then

            if IsFalse $zpool28fix; then
                zfs_snapshots=`$zfs_cmd list -H -o name -t snapshot | grep -E -e "^.*@(${prefixes})?${date_pattern}--${ttl_pattern}$" | sed -e 's#/.*@#@#'`
            else
                zfs_snapshots=`$zfs_cmd list -H -o name -t snapshot | grep -E -e "^.*@(${prefixes})?${date_pattern}--${ttl_pattern}$"`
            fi

            current_time=`date +%s`
            for i in `echo $zfs_snapshots | xargs printf "%s\n" | $ESED -e "s/^.*@//" | sort -u`; do
                create_time=$(Date2Timestamp `echo "$i" | $ESED -e "s/--${ttl_pattern}$//; s/^(${prefixes})?//"`)
                if IsTrue $delete_snapshots; then
                    stay_time=$(TTL2Seconds `echo $i | $ESED -e "s/^(${prefixes})?${date_pattern}--//"`)
                    [ $current_time -gt $(($create_time + $stay_time)) ] \
                        && rm_snapshot_pattern="$rm_snapshot_pattern $i"
                fi
                if [ "$force_delete_snapshots_age" -ne -1 ]; then
                    [ $current_time -gt $(($create_time + $force_delete_snapshots_age)) ] \
                        && rm_snapshot_pattern="$rm_snapshot_pattern $i"
                fi
            done

            if [ "$rm_snapshot_pattern" != '' ]; then
                rm_snapshots=$(echo $zfs_snapshots | xargs printf '%s\n' | grep -E -e "@`echo $rm_snapshot_pattern | sed -e 's/ /|/g'`" | sort -u)
                for i in $rm_snapshots; do
                    RmZfsSnapshot -r $i
                done
            fi
        fi

        # delete all snapshots
        if IsTrue $delete_all_snapshots; then
            if [ "$zopt" != '-r' ]; then
                rm_snapshots=`$zfs_cmd list -H -o name -t snapshot | grep -E -e "^$1@(${prefixes})?${date_pattern}--${ttl_pattern}$"`
                for i in $rm_snapshots; do
                    RmZfsSnapshot $i
                done
            else
                rm_snapshots=`$zfs_cmd list -H -o name -t snapshot | grep -E -e "^$1@(${prefixes})?${date_pattern}--${ttl_pattern}$"`
                for i in $rm_snapshots; do
                    RmZfsSnapshot -r $i
                done
            fi
        fi
    fi
done
