#!/bin/sh

# "THE BEER-WARE LICENSE":
# <graudeejs@yandex.com> wrote this file. As long as you retain this notice you
# can do whatever you want with this stuff. If we meet some day, and you think
# this stuff is worth it, you can buy me a beer in return. Aldis Berjoza

# wiki:             https://github.com/graudeejs/zfSnap/wiki
# repository:       https://github.com/graudeejs/zfSnap
# Bug tracking:     https://github.com/graudeejs/zfSnap/issues

# import zfSnap's library
zfSnap_lib_dir=~/git/zfSnap/
. "$zfSnap_lib_dir"/zfSnap_lib.sh

## FUNCTIONS

Help() {
    cat << EOF
${0##*/} v${VERSION} by Aldis Berjoza

Syntax:
${0##*/} [ options ] zpool/filesystem ...

OPTIONS:
  -a ttl       = Set how long snapshot should be kept
  -d           = Delete old snapshots
  -D pool/fs   = Delete all zfSnap snapshots of specific pool/fs (ignore ttl)
  -e           = Return number of failed actions as exit code.
  -F age       = Force delete all snapshots exceeding age
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
  -z           = Force new snapshots to have 00 seconds!

LINKS:
  wiki:             https://github.com/graudeejs/zfSnap/wiki
  repository:       https://github.com/graudeejs/zfSnap
  Bug tracking:     https://github.com/graudeejs/zfSnap/issues

EOF
    Exit 0
}

# make sure arguments were provided
if [ "$#" -eq 0 ] && IsFalse $test_mode; then
    Help
fi

# main loop; get options, process snapshot creation
while [ "$1" ]; do
    while getopts :a:dD:eF:hnp:PrRsSvz opt; do
        case "$opt" in
            a) ttl="$OPTARG"
               printf "%s" "$ttl" | grep -q -E -e "^[0-9]+$" && ttl=`Seconds2TTL "$ttl"`
               ValidTTL "$ttl" || Fatal "Invalid TTL: $ttl"
               ;;
            d) delete_snapshots="true";;
            D) if [ "$zopt" != '-r' ]; then
                   delete_specific_fs_snapshots="$delete_specific_fs_snapshots $OPTARG"
               else
                   delete_specific_fs_snapshots_recursively="$delete_specific_fs_snapshots_recursively $OPTARG"
               fi
               ;;
            e) count_failures="true";;
            F) force_delete_snapshots_age=`TTL2Seconds "$OPTARG"`;;
            h) Help;;
            n) dry_run="true";;
            p) prefix="$OPTARG"; prefixes="${prefixes:+$prefixes|}$prefix";;
            P) prefix="";;
            r) zopt='-r';;
            R) zopt='';;
            s) pools="${pools:-`$zpool_cmd list -H -o name`}"
               for i in "$pools"; do
                   $zpool_cmd status $i | grep -q -e 'resilver in progress' && skip_pools="$skip_pools $i"
               done
               ;;
            S) pools="${pools:-`$zpool_cmd list -H -o name`}"
               for i in "$pools"; do
                   $zpool_cmd status $i | grep -q -e 'scrub in progress' && skip_pools="$skip_pools $i"
               done
               ;;
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

# delete snapshots
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
if [ "$delete_specific_fs_snapshots" != '' ]; then
    rm_snapshots=`$zfs_cmd list -H -o name -t snapshot | grep -E -e "^($(echo "$delete_specific_fs_snapshots" | tr ' ' '|'))@(${prefixes})?${date_pattern}--${ttl_pattern}$"`
    for i in $rm_snapshots; do
        RmZfsSnapshot $i
    done
fi

if [ "$delete_specific_fs_snapshots_recursively" != '' ]; then
    rm_snapshots=`$zfs_cmd list -H -o name -t snapshot | grep -E -e "^($(echo "$delete_specific_fs_snapshots_recursively" | tr ' ' '|'))@(${prefixes})?${date_pattern}--${ttl_pattern}$"`
    for i in $rm_snapshots; do
        RmZfsSnapshot -r $i
    done
fi


IsTrue $count_failures && Exit $failures
Exit 0
# vim: set ts=4 sw=4 expandtab:
