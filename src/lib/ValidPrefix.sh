# Check validity of a prefix
local snapshot_prefix="$1"

[ -z "$PREFIXES" ] && [ -z "$snapshot_prefix" ] && return 0

local i
for i in $PREFIXES; do
    [ "$snapshot_prefix" = "$i" ] && return 0
done

return 1