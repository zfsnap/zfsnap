# Mathematically add a TTL to a date
#   When a TTL is added to a date, each field is added independently,
#   any month overflows are carried into years, and then all overflows
#   are carried normally from right to left (e.g. 2009-02-27 plus 1m3d
#   results in 2009-03-30 rather than 2009-04-02).
#
#   Corner case: adding 1m to 2009-10-31 will result in 2009-12-01
#   rather than 2009-11-30. Because there are only 30 days in November,
#   precisely one month after October 31st is ambiguous. This returns
#   the more conservative (later) option.
# Accepts a zfsnap date and a TTL
# Retvals a zfsnap date
ValidDate "$1" && local orig_date="$1" || { RETVAL=''; return 1; }
local ttl="$2"

# break date into components; strip leading zeros
local y="${orig_date%%-*}" && y=${y#0} && orig_date=${orig_date#*-}
local m="${orig_date%%-*}" && m=${m#0} && orig_date=${orig_date#*-}
local d="${orig_date%%_*}" && d=${d#0} && orig_date=${orig_date#*_}
local h="${orig_date%%.*}" && h=${h#0} && orig_date=${orig_date#*.}
local M="${orig_date%%.*}" && M=${M#0} && orig_date=${orig_date#*.}
local s="${orig_date}" && s=${s#0}

while [ -n "$ttl" ]; do
    case "$ttl" in
        *y*) y=$((${ttl%%y*} + $y)); ttl=${ttl#*y} ;;
        *m*) m=$((${ttl%%m*} + $m)); ttl=${ttl#*m} ;;
        *w*) d=$(((${ttl%%w*} * 7) + $d)); ttl=${ttl#*w} ;;
        *d*) d=$((${ttl%%d*} + $d)); ttl=${ttl#*d} ;;
        *h*) h=$((${ttl%%h*} + $h)); ttl=${ttl#*h} ;;
        *M*) M=$((${ttl%%M*} + $M)); ttl=${ttl#*M} ;;
            *s) s=$((${ttl%%s*} + $s)); ttl=${ttl#*s} ;;
            *) Warn "Invalid TTL '$ttl' in DatePlusTTL."; RETVAL=''; return 1 ;;
    esac
done

# roll seconds into minutes into hours into days
[ $s -ge 60 ] && M=$(($M + ($s / 60))) && s=$(($s % 60))
[ $M -ge 60 ] && h=$(($h + ($M / 60))) && M=$(($M % 60))
[ $h -ge 24 ] && d=$(($d + ($h / 24))) && h=$(($h % 24))

# days, months, years
while true; do
    # roll months into years
    [ $m -gt 12 ] && y=$(($y + ($m / 12))) && m=$(($m % 12))
    [ $m -eq 0 ] && m=1

    # roll days into months
    local month_lengths='31 28 31 30 31 30 31 31 30 31 30 31'
    local m_num=0
    local m_length
    for m_length in $month_lengths; do
        m_num=$(($m_num + 1))

        # skip if we're not to current month yet
        [ $m -gt $m_num ] && continue

        # adjust if february in a leap year
        [ $m_num -eq 2 ] && IsLeapYear "$y" && m_length=29

        [ $d -le $m_length ] && break 2

        d=$(($d - $m_length)) && m=$(($m + 1))
    done
done

# pad with a zero
[ ${#m} -eq 1 ] && m="0${m}" ; [ ${#d} -eq 1 ] && d="0${d}"
[ ${#h} -eq 1 ] && h="0${h}" ; [ ${#M} -eq 1 ] && M="0${M}"
[ ${#s} -eq 1 ] && s="0${s}"

RETVAL="${y}-${m}-${d}_${h}.${M}.${s}" && return 0
