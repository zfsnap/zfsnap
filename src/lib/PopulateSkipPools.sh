# Populates the $SKIP_POOLS global variable; does not return anything
[ -z "$1" ] && Fatal 'PopulateSkipPools requires an argument!'
POOLS=${POOLS:-`$ZPOOL_CMD list -H -o name`}

local i
for i in $POOLS; do
    ZSTATUS=`"$ZPOOL_CMD" status "$i"`
    [ -z "${ZSTATUS##*$1 in progress*}" ] && SKIP_POOLS="${SKIP_POOLS:+$SKIP_POOLS }$i"
done
