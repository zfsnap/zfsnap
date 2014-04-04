#!/bin/sh

# This file is licensed under the BSD-3-Clause license.
# See the AUTHORS and LICENSE files for more information.

# If there is a global system configuration file, suck it in.
#
if [ -r /etc/defaults/periodic.conf ]; then
	. /etc/defaults/periodic.conf
	source_periodic_confs
fi

# xPERIODICx_zfsnap_enable			- Enable xPERIODICx snapshots (values: YES | NO)
# xPERIODICx_zfsnap_flags			- zfsnap generic flags (except -v and -d)
# xPERIODICx_zfsnap_fs				- Space separated zfs filesystems to create non-recursive snapshots
# xPERIODICx_zfsnap_recursive_fs	- Space separated zfs filesystems to create recursive snapshots
# xPERIODICx_zfsnap_ttl				- Set Time To Live
# xPERIODICx_zfsnap_verbose			- Verbose output (values: YES | NO)
# xPERIODICx_zfsnap_enable_prefix	- Create snapshots with prefix (values: YES | NO) (Default = YES)
# xPERIODICx_zfsnap_prefix			- set prefix for snapshots (Default = xPERIODICx)

case "${xPERIODICx_zfsnap_enable-"NO"}" in
	[Yy][Ee][Ss])
		OPTIONS="$xPERIODICx_zfsnap_flags"

		case "${xPERIODICx_zfsnap_verbose-"NO"}" in
		[Yy][Ee][Ss])
			OPTIONS="$OPTIONS -v"
			;;
		esac

		case "${xPERIODICx_zfsnap_enable_prefix-"YES"}" in
		[Yy][Ee][Ss])
			OPTIONS="$OPTIONS -p ${xPERIODICx_zfsnap_prefix:-"xPERIODICx-"}"
			;;
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
			echo "ERR: Unexpected error" > /dev/stderr
			exit 1
			;;
		esac

		xPREFIXx/zfsnap $OPTIONS -a ${xPERIODICx_zfsnap_ttl:-"$default_ttl"} $xPERIODICx_zfsnap_fs -r $xPERIODICx_zfsnap_recursive_fs
		exit $?
		;;

	*)
		exit 0
		;;
esac

# vim: set ts=4 sw=4:
