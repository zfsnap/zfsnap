# Check validity of TTL
local ttl="$1"

[ -z "$ttl" ] && return 1
[ "$ttl" = 'forever' ] && return 0

while [ -n "$ttl" ]; do
    [ -z "${ttl##0*}" ] && return 1 # leading zeros not accepted
    case "$ttl" in
        *y*) IsInt "${ttl%y*}" && ttl=${ttl##*y} || return 1 ;;
        *m*) IsInt "${ttl%m*}" && ttl=${ttl##*m} || return 1 ;;
        *w*) IsInt "${ttl%w*}" && ttl=${ttl##*w} || return 1 ;;
        *d*) IsInt "${ttl%d*}" && ttl=${ttl##*d} || return 1 ;;
        *h*) IsInt "${ttl%h*}" && ttl=${ttl##*h} || return 1 ;;
        *M*) IsInt "${ttl%M*}" && ttl=${ttl##*M} || return 1 ;;
            *s) IsInt "${ttl%s*}" && ttl=${ttl##*s} || return 1 ;;
            *) return 1 ;;
    esac
done

return 0
