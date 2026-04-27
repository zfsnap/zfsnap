# Accepts two /valid/ zfsnap dates
# Returns 0 if date1 is greater or equal
# Returns 1 if date2 is greater
# returns 2 if input is invalid
ValidDate "$1" && local date1="$1" || return 2
ValidDate "$2" && local date2="$2" || return 2

while [ -n "$date1" ]; do
    # get the first field and strip off any leading zeros
    local field1=${date1%%[-_.]*} && field1=${field1#0}
    local field2=${date2%%[-_.]*} && field2=${field2#0}

    [ "$field1" -gt "$field2" ] && return 0
    [ "$field1" -eq "$field2" ] || return 1

    # if no separators left (seconds), bail
    [ -z "${date1%%*[-_.]*}" ] || break

    date1=${date1#*[-_.]} && date2=${date2#*[-_.]}
done

return 0
