#!/bin/sh

# This file is licensed under the BSD-3-Clause license.
# See the AUTHORS and LICENSE files for more information.

# If there is a global system configuration file, suck it in.
if [ -r /etc/defaults/periodic.conf ]; then
    . /etc/defaults/periodic.conf
    source_periodic_confs
fi

# xPERIODICx_zfsnap_enable          - Enable xPERIODICx snapshots (values: YES | NO)
# xPERIODICx_zfsnap_flags           - `zfsnap snapshot` flags
# xPERIODICx_zfsnap_delete_flags    - `zfsnap destroy` flags
# xPERIODICx_zfsnap_fs              - Space-separated ZFS filesystems to manage non-recursive snapshots
# xPERIODICx_zfsnap_recursive_fs    - Space-separated ZFS filesystems to manage recursive snapshots
# xPERIODICx_zfsnap_ttl             - Explicit TTL value
# xPERIODICx_zfsnap_verbose         - Verbose output (values: YES | NO)
# xPERIODICx_zfsnap_enable_prefix   - Create snapshots with prefix (values: YES | NO) (Default = YES)
# xPERIODICx_zfsnap_prefix          - set prefix for snapshots (Default = xPERIODICx)
# xPERIODICx_zfsnap_delete_prefixes - Space-separated list of prefixes of expired zfsnap snapshots to delete

case "${xPERIODICx_zfsnap_enable-"NO"}" in
    [Yy][Ee][Ss])
        CREATE_OPTIONS="$xPERIODICx_zfsnap_flags"
        DESTROY_OPTIONS="$xPERIODICx_zfsnap_delete_flags"

        case "${xPERIODICx_zfsnap_verbose-"NO"}" in
            [Yy][Ee][Ss])
                CREATE_OPTIONS="$CREATE_OPTIONS -v"
                DESTROY_OPTIONS="$DESTROY_OPTIONS -v"
            ;;
        esac

        case "${xPERIODICx_zfsnap_enable_prefix-"YES"}" in
            [Yy][Ee][Ss]) CREATE_OPTIONS="$CREATE_OPTIONS -p ${xPERIODICx_zfsnap_prefix:-"xPERIODICx-"}" ;;
        esac

        case 'xPERIODICx' in
            'hourly')
                default_ttl='3d'
                ;;
            'daily'|'reboot')
                default_ttl='1w'
                ;;
            'weekly')
                default_ttl='1m'
                ;;
            'monthly')
                default_ttl='6m'
                ;;
            *)
                printf '%s\n' "ERR: Unexpected error" >&2
                exit 1
                ;;
        esac

        # Destroy before create, just in case the pool is out of space
        xPREFIXx/zfsnap destroy $DESTROY_OPTIONS -p "hourly- daily- weekly- monthly- reboot- $xPERIODICx_zfsnap_delete_prefixes" $xPERIODICx_zfsnap_fs -r $xPERIODICx_zfsnap_recursive_fs && \
            xPREFIXx/zfsnap snapshot $CREATE_OPTIONS -a ${xPERIODICx_zfsnap_ttl:-"$default_ttl"} $xPERIODICx_zfsnap_fs -r $xPERIODICx_zfsnap_recursive_fs
        exit $?
        ;;

    *)
        exit 0
        ;;
esac

# vim: set ts=4 sw=4:
