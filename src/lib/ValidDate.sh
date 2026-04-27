# Check validity of a zfsnap date
[ -z "$1" ] && return 1
[ -z "${1##$DATE_PATTERN}" ] && return 0 || return 1
