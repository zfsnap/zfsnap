# Retvals the date (anything that matches the "date pattern")
# If no "date pattern" is found, it will return 1.
local snapshot_name="$1"
[ -z "$snapshot_name" ] && RETVAL='' && return 1

# make sure it contains a date
[ -z "${snapshot_name##*$DATE_PATTERN*}" ] || { RETVAL=''; return 1; }

local pre_date="${snapshot_name%$DATE_PATTERN*}"
local post_date="${snapshot_name##*$DATE_PATTERN}"

local snapshot_date="${snapshot_name##$pre_date}"
snapshot_date=${snapshot_date%%$post_date}

if [ -z "${snapshot_date##$DATE_PATTERN}" ]; then
    RETVAL=$snapshot_date && return 0
else
    RETVAL='' && return 1
fi
