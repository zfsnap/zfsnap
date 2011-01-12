#!/bin/sh

# If there is a global system configuration file, suck it in.
#
if [ -r /etc/defaults/periodic.conf ]; then
	. /etc/defaults/periodic.conf
	source_periodic_confs
fi

# xPERIODICx_zfsnap_enable			- Enable xPERIODICx snapshots (values: YES | NO)
# xPERIODICx_zfsnap_fs				- Space separated zfs filesystems to create non-recursive snapshots
# xPERIODICx_zfsnap_recursive_fs	- Space separated zfs filesystems to create recursive snapshots
# xPERIODICx_zfsnap_ttl				- Set Time To Live (3d by default)
# xPERIODICx_zfsnap_delete 			- Delete old snapshots (values: YES | NO)
# xPERIODICx_zfsnap_verbose			- Verbose output (values: YES | NO)

case "${xPERIODICx_zfsnap_enable-"NO"}" in
	[Yy][Ee][Ss])
		OPTIONS=""

		case "${xPERIODICx_zfsnap_verbose-"NO"}" in
			[Yy][Ee][Ss])
				OPTIONS="$OPTIONS -v"
				;;
		esac

		case "${xPERIODICx_zfsnap_delete-"NO"}" in
			[Yy][Ee][Ss])
				OPTIONS="$OPTIONS -d"
				;;
		esac

		zfSnap $OPTIONS -a ${xPERIODICx_zfsnap_ttl:-"3d"} $xPERIODICx_zfsnap_fs -r $xPERIODICx_zfsnap_recursive_fs
		;;

	*)
		exit 0
		;;
esac

# vim: set ts=4 sw=4:
