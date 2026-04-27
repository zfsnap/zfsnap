# Retvals the pool name (anything before the first '/' or '@')
# If no valid pool is found, it will return 1.
local pool_name="${1%%[/@]*}"

if PoolExists "$pool_name"; then
    RETVAL=$pool_name && return 0
else
    RETVAL='' && return 1
fi
