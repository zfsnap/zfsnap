#!/bin/sh -

: ${daily_synczfs_enable="NO"}
: ${daily_synczfs_root=""}
: ${daily_synczfs_user="backup"}

# daily_synczfs_servers:
#		space separated list of server names (resolvable)
#
# daily_synczfs_<server>_input_filter:
#		all data on remote system would be piped through this command[s]
#		possible usage:
#		 - compression: '| xz -9e' or '| bzip2 -9';
#		 - rate limiting: '| mbuffer -r 256k' or '| pv -L 256k', notice that misc/mbuffer or sysutils/pv should be installed.
#
# daily_synczfs_<server>_output_filter:
#		all data on local system would be piped through this command[s]
#		possible usage:
#		 - decompression: '| xz -d' or '| bzip2 -d'.
#
# daily_synczfs_<server>_fs:
#		space separated list of remote filesystem aliases
#
# daily_synczfs_<server>_hostname:
#		full host name of remote system, if not present substituted by <server>
#
# daily_synczfs_<server>_<alias>_rfsname:
#		full zfs filesystem name on remote system
#
# daily_synczfs_<server>_<alias>_fsname:
#		last part of zfs filesystem name on local system (resides in daily_synczfs_root)

# Except configuring task you also should:
#  1. Create key (ssh-keygen -t dsa -b 1024), add it to remote .ssh/authorized_keys and auth system in .ssh/known_hosts
#  2. On remote server allow named user to dump selected filesystem (zfs allow user hold,send rfsname)

# If there is a global system configuration file, suck it in.

if [ -r /etc/defaults/periodic.conf ]; then
	. /etc/defaults/periodic.conf
	source_periodic_confs
fi

echo "Synchronizing ZFS snapshots:"

unwind=`readlink -nf N $0`
. `dirname $unwind`/funcs

if checkyesno daily_synczfs_enable; then
	checknotempty daily_synczfs_servers && exit 2

	checknotempty daily_synczfs_root && exit 2
	if ! zfs list -Ht filesystem "$daily_synczfs_root" >/dev/null 2>&1; then
		echo "  \$daily_synczfs_enable is set but \$daily_synczfs_root doesn't point to zfs filesystem."
		exit 2
	fi

	if ! su "$daily_synczfs_user" -c : >/dev/null 2>&1; then
		echo "  \$daily_synczfs_enable is set but \$daily_synczfs_user point to unknown or unavailable user."
		exit 2
	fi
	zfs allow "$daily_synczfs_user" create,mount,receive "$daily_synczfs_root"

	for server in $daily_synczfs_servers; do
		# getting hostname, default to server name
		eval hostname=\"\${daily_synczfs_${server}_hostname}\"
		if [ -z $hostname ]; then
			hostname="$server"
		fi

		# get local/remote filters
		eval ifilter=\"\${daily_synczfs_${server}_input_filter}\"
		eval ofilter=\"\${daily_synczfs_${server}_output_filter}\"

		# check server access
		if ! ping -oc 5 $hostname >/dev/null 2>&1; then
			echo "  Server $server[$hostname] is mentioned in \$daily_synczfs_servers but can't be pinged."
			exit 2
		fi

		eval aliases=\"\${daily_synczfs_${server}_fs}\"
		for alias in $aliases; do
			# check remote access
			if ! su "$daily_synczfs_user" -c "ssh -oBatchMode=yes $daily_synczfs_user@$hostname :" >/dev/null 2>&1; then
				echo "Server $server is mentioned in \$daily_synczfs_servers but provides no access."
				exit 2
			fi

			# check remote filesystem
			checknotempty daily_synczfs_${server}_${alias}_rfsname && exit 2
			eval rfsname=\"\${daily_synczfs_${server}_${alias}_rfsname}\"
			if ! echo $rfsname | grep -q '^[a-zA-Z0-9/\._-]\+$'; then
				echo "  Server $server is mentioned but \$daily_synczfs_${server}_${alias}_rfsname [$rfsname] contains banned chars."
				exit 2
			elif ! su "$daily_synczfs_user" -c "ssh -oBatchMode=yes $daily_synczfs_user@$hostname \"zfs list -Ht filesystem $rfsname\"" >/dev/null 2>&1; then
				echo "  Server $server is mentioned but \$daily_synczfs_${server}_${alias}_rfsname doesn't exist."
				exit 2
			fi

			rsnaps=`mktemp -t synczfs`
			su "$daily_synczfs_user" -c "ssh -oBatchMode=yes $daily_synczfs_user@$hostname \"zfs list -Hrt snapshot -d1 $rfsname\"" | awk 'BEGIN{FS="[ @\t]+"}{print$2}' > $rsnaps

			# check local filesystem
			checknotempty daily_synczfs_${server}_${alias}_fsname && exit 2
			eval fsname=\"\${daily_synczfs_${server}_${alias}_fsname}\"
			if ! echo $fsname | grep -q '^[a-zA-Z0-9\._-]\+$'; then
				echo "  Server $server is mentioned in \$daily_synczfs_${server}_${alias}_fsname contains banned chars."
				exit 2
			elif ! zfs list -Ht filesystem $daily_synczfs_root/$fsname >/dev/null 2>&1; then
				su "$daily_synczfs_user" -c "zfs create "$daily_synczfs_root/$fsname" ; ssh -oBatchMode=yes $daily_synczfs_user@$hostname \"zfs send -R $rfsname@`tail -1 $rsnaps` $ifilter\" $ofilter | zfs receive -Fu $daily_synczfs_root/$fsname ; zfs inherit mountpoint $daily_synczfs_root/$fsname"
			else
				lsnaps=`mktemp -t synczfs`
				zfs list -Hrt snapshot -d1 "$daily_synczfs_root/$fsname" | awk 'BEGIN{FS="[ @\t]+"}{print$2}' > $lsnaps
				common=`join $rsnaps $lsnaps | tail -1`
				if [ -z "$common" ]; then
					echo "  $rfsname on $server shares no snapshots with $fsname."
					exit 2
				else
					# dropping local surplus
					lastone=no
					for snapshot in `cat $lsnaps`; do
						if [ "_$snapshot" = "_$common" ]; then
							lastone=yes
							continue
						fi
						if [ "_$lastone" = "_yes" ]; then
							zfs destroy "$daily_synczfs_root/$fsname@$snapshot"
						fi
					done
				fi
				rm -rf $lsnaps
				su "$daily_synczfs_user" -c "ssh -oBatchMode=yes $daily_synczfs_user@$hostname \"zfs send -I $rfsname@$common $rfsname@`tail -1 $rsnaps` $ifilter\" $ofilter | zfs receive -F $daily_synczfs_root/$fsname"
			fi
			rm -rf $rsnaps
		done
	done
fi
