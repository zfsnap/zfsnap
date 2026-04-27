# Returns 0 if argument is an integer
[ -z "${1##*[!0-9]*}" ] && return 1 || return 0
