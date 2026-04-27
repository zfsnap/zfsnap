# Retvals the file system name (everything before the '@')
# ZFS reserves '@' to deliminate snapshots. At max, there will be one per dataset.
# If no valid file system is found, it will return 1.
local snapshot="$1"
local file_system="${snapshot%%@*}"

if FSExists "$file_system"; then
    RETVAL=$file_system && return 0
else
    RETVAL='' && return 1
fi
