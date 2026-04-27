# Retvals the snapshot name (everything after the '@')
# ZFS reserves '@' to deliminate snapshots. At max, there will be one per dataset.
# If no valid snapshot name is found, it will return 1.
local snapshot="$1"
local snapshot_name="${snapshot##*@}"

if ValidSnapshotName "$snapshot_name"; then
    RETVAL=$snapshot_name && return 0
else
    RETVAL='' && return 1
fi
