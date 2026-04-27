# Divide one integer by another
#   This approach uses a long division approach in order to avoid problem with
#   performing arithmetic on numerators larger than the current shell's int
#   size (many are limited to 32-bit, but even 64-bit is insufficient in some
#   extreme scenarios).
local numer="$1" # can be any size
local denom="$2" # must be <= 2147483647
local answer=''
local chunk=''
local first=''

! IsInt "$numer" && RETVAL='' && return 1
! IsInt "$denom" && RETVAL='' && return 1

# as long as there's digits to operate on
while [ -n "$numer" ]; do
    first=${numer%${numer#?}} # get first digit
    numer=${numer#${first}} # strip off first digit
    chunk="${chunk}${first}"

    if [ ${chunk:-0} -ge $denom ]; then
        answer="${answer}$(( $chunk / $denom ))" # append quotient
        chunk=$(( $chunk % $denom )) # assign remainder
    else
        [ -n "$answer" ] && answer="${answer}0" # don't build leading zeros
    fi
    [ $chunk -eq 0 ] && chunk='' # protect against leading zeros
done

RETVAL=$answer && return 0
