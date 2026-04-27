# Returns 1 if ZFS operations on given pool should be skipped.
# This function's name implies the opposite of what it does. It
# should be renamed, but I can't come up with anything intuitive and short.
local i
for i in $SKIP_POOLS; do
    if TrimToPool "$1" && [ "$RETVAL" = "$i" ]; then
        IsTrue "$VERBOSE" && Note "No actions will be performed on '$1'. Resilver or Scrub is running on pool."
        return 1
    fi
done
return 0
