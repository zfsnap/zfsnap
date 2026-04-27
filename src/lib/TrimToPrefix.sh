# Retvals the prefix in a snapshot name (anything prior to the "snapshot date")
# If no valid "snapshot date" or prefix is found, it will return 1.
local snapshot_name="$1"

# make sure it contains a date
[ -z "${snapshot_name##*$DATE_PATTERN*}" ] || { RETVAL=''; return 1; }

local snapshot_prefix="${snapshot_name%$DATE_PATTERN*}"
if ValidPrefix "$snapshot_prefix"; then
    RETVAL=$snapshot_prefix && return 0
else
    RETVAL='' && return 1
fi
