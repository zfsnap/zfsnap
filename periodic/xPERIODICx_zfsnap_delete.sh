#!/bin/sh

# This file is licensed under the BSD-3-Clause license.
# See the AUTHORS and LICENSE files for more information.

# If there is a global system configuration file, suck it in.
#
if [ -r /etc/defaults/periodic.conf ]; then
    . /etc/defaults/periodic.conf
    source_periodic_confs
fi

# xPERIODICx_zfsnap_delete_enable   - Delete old snapshots periodicaly (values: YES | NO)
# xPERIODICx_zfsnap_delete_flags    - `zfsnap destroy` flags
# xPERIODICx_zfsnap_delete_verbose  - Verbose output (values: YES | NO)
# xPERIODICx_zfsnap_delete_prefixes - Space-separated list of prefixes of expired zfsnap snapshots to delete
#                                     'hourly-', 'daily-', 'weekly-', 'monthly-', and 'reboot-' prefixes are hardcoded

case "${xPERIODICx_zfsnap_delete_enable-"NO"}" in
    [Yy][Ee][Ss])
        OPTIONS="$xPERIODICx_zfsnap_delete_flags"

        case "${xPERIODICx_zfsnap_delete_verbose-"NO"}" in
            [Yy][Ee][Ss]) OPTIONS="$OPTIONS -v" ;;
        esac

        for prefix in $xPERIODICx_zfsnap_delete_prefixes; do
            OPTIONS="$OPTIONS -p $prefix"
        done

        xPREFIXx/zfsnap destroy $OPTIONS -p 'hourly-' -p 'daily-' -p 'weekly-' -p 'monthly-' -p 'reboot-'
        exit $?
        ;;

    *)
        exit 0
        ;;
esac

# vim: set ts=4 sw=4:
