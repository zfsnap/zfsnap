#!/bin/sh

# If there is a global system configuration file, suck it in.
#
if [ -r /etc/defaults/periodic.conf ]; then
	. /etc/defaults/periodic.conf
	source_periodic_confs
fi

# xPERIODICx_zfsnap_delete 			- Delete old snapshots (values: YES | NO)
# xPERIODICx_zfsnap_enable			- Enable xPERIODICx snapshots (values: YES | NO)
# xPERIODICx_zfsnap_flags			- zfSnap generic flags (except -v and -d)
# xPERIODICx_zfsnap_fs				- Space separated zfs filesystems to create non-recursive snapshots
# xPERIODICx_zfsnap_recursive_fs	- Space separated zfs filesystems to create recursive snapshots
# xPERIODICx_zfsnap_ttl				- Set Time To Live
# xPERIODICx_zfsnap_verbose			- Verbose output (values: YES | NO)

case "${xPERIODICx_zfsnap_enable-"NO"}" in
	[Yy][Ee][Ss])
		delete_snapshots=0
		OPTIONS="$xPERIODICx_zfsnap_flags"

		case "${xPERIODICx_zfsnap_verbose-"NO"}" in
		[Yy][Ee][Ss])
			OPTIONS="$OPTIONS -v"
			;;
		esac

		case "${xPERIODICx_zfsnap_delete-"NO"}" in
		[Yy][Ee][Ss])
			OPTIONS="$OPTIONS -d"
			delete_snapshots=1
			;;
		esac
		
		case 'xPERIODICx' in
		'hourly')
			default_ttl='3d'
			[ $delete_snapshots -ne 0 ] \
				&& echo "WARN: It is not recommended to delete old snapshots every hour" > /dev/stderr
			;;
		'daily')
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

		zfSnap $OPTIONS -a ${xPERIODICx_zfsnap_ttl:-"$default_ttl"} $xPERIODICx_zfsnap_fs -r $xPERIODICx_zfsnap_recursive_fs
		exit $?
		;;

	*)
		exit 0
		;;
esac

# vim: set ts=4 sw=4:
