# Convert bytes to human readable format
#
#   One decimal place of precision is added for answers that are only 1 or 2
#   digits in length. This is for two reasons.
#     1. Practical accuracy: imprecision is inherent to human-readable units;
#        however, the decimal in 1.9TiB is 90% of 1TiB. In 100.9GiB its less
#        than 1%. 1% feels like a sane arbitrary cutoff.
#     2. Length: limiting to 5 total characters seems like a sane limit.
# Accepts 1 integer
# Retvals human readable size: e.g. 3.2G
local bytes="$1"
local prev_answer=''
local answer="$bytes"
local count=0

# must be an integer
! IsInt "$bytes" && RETVAL='' && return 1

while [ ${#answer} -gt 9 ] || [ ${answer:-0} -ge 1024 ]; do
    LongDivide $answer 1024 && prev_answer=$answer && answer=$RETVAL
    count=$(( $count + 1 ))
done

# if 2 digits or fewer, add one decimal of precision
if [ ${#answer} -le 2 ] && [ -n "$prev_answer" ]; then
    local remainder=$(( $prev_answer % 1024 ))
    answer="${answer}.$(( ${remainder}0 / 1024 ))"
    answer=${answer%.0} # remove .0
fi

local unit
for unit in '' K M G T P E Z; do
    [ $count -eq 0 ] && break
    count=$(( $count - 1 ))
done

RETVAL="${answer}${unit}" && return 0

