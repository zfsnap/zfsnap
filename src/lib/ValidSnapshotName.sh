# Returns 0 if it's a snapshot name that matches zfsnap's name pattern
# This also filters for any prefixes in effect
IsSnapshot "$1" && return 1
local snapshot_name="$1"

TrimToPrefix "$snapshot_name" && local snapshot_prefix="$RETVAL" || return 1
TrimToDate "$snapshot_name" && local snapshot_date="$RETVAL" || return 1
TrimToTTL "$snapshot_name" && local snapshot_ttl="$RETVAL" || return 1

local rebuilt_name="${snapshot_prefix}${snapshot_date}--${snapshot_ttl}"
[ "$rebuilt_name" = "$snapshot_name" ] && return 0 || return 1
