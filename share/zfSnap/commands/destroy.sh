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
  -r           = Operate recursively on all ZFS file systems after this switch.
  -R           = Do not operate recursively on all ZFS file systems after this switch.
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
delete_all_snapshots="false"        # Should all snapshots be deleted, regardless of TTL
rm_snapshots=''                     # List of specific snapshots to delete

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
            r) recursive='true';;
            R) recursive='false';;
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
        if IsTrue $recursive; then
            zfs_snapshots=`$zfs_cmd list -H -o name -t snapshot | grep -E -e "^$1(.*)?@(${prefixes})?${date_pattern}--${ttl_pattern}$"`
        else
            zfs_snapshots=`$zfs_cmd list -H -o name -t snapshot | grep -E -e "^$1@(${prefixes})?${date_pattern}--${ttl_pattern}$"`
        fi

        if IsTrue $delete_all_snapshots; then
            rm_snapshots=$zfs_snapshots
        else
            current_time=`date +%s`
            # TODO, both create_time and stay_time could be cached
            for i in $zfs_snapshots; do
                snapshot_name=${i#*@}
                create_time=$(Date2Timestamp `echo "$snapshot_name" | $ESED -e "s/--${ttl_pattern}$//; s/^(${prefixes})?//"`)

                if [ "$force_delete_snapshots_age" -ne -1 ]; then
                    if [ $current_time -gt $(($create_time + $force_delete_snapshots_age)) ]; then
                      rm_snapshots="$rm_snapshots $i"
                    fi
                else
                    stay_time=$(TTL2Seconds ${snapshot_name##*--})
                    if [ $current_time -gt $(($create_time + $stay_time)) ]; then
                        rm_snapshots="$rm_snapshots $i"
                    fi
                fi
            done
        fi

        for i in $rm_snapshots; do
            RmZfsSnapshot "$i"
        done
        rm_snapshots=''

        shift
    fi
done
