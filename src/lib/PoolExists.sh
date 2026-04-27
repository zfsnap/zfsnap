# Returns 0 if pool exists
POOLS=${POOLS:-`$ZPOOL_CMD list -H -o name`}

local i
for i in $POOLS; do
    [ "$1" = "$i" ] && return 0
done

return 1
