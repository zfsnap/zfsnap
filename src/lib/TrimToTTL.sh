# Retvals the TTL (anything after the last '--')
# If no valid TTL is found, it will return 1.
local snapshot="$1"
local ttl="${snapshot##*--}"

if ValidTTL "$ttl"; then
    RETVAL=$ttl && return 0
else
    RETVAL='' && return 1
fi
