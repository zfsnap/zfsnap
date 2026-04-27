# Accepts one integer
# Returns 0 if supplied year is a leap year
local year="$1"
IsInt "$year" || return 1

[ $(($year % 400)) -eq 0 ] && return 0
[ $(($year % 100)) -eq 0 ] && return 1
[ $(($year % 4)) -eq 0 ] && return 0

return 1
