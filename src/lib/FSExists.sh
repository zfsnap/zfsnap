# Returns 0 if filesystem exists
FS_LIST=${FS_LIST:-`$ZFS_CMD list -H -o name`}

local i
for i in $FS_LIST; do
    [ "$1" = "$i" ] && return 0
done

return 1
