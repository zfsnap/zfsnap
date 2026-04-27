# Returns 0 if it looks like a snapshot

case "$1" in
    [!@]*@*[!@]) return 0;;
    *) return 1;;
esac
