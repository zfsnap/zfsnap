# Removes ZFS snapshot
SkipPool "$1" || return 1

local zfs_destroy="$ZFS_CMD destroy $*"

# hardening: make really, really sure we are deleting a snapshot
if IsSnapshot "$1"; then
    if IsFalse "$DRY_RUN"; then
        if $zfs_destroy >&2; then
            IsTrue "$VERBOSE" && printf '%s ... DONE\n' "$zfs_destroy"
        else
            IsTrue "$VERBOSE" && printf '%s ... FAIL\n' "$zfs_destroy"
        fi
    else
        printf '%s\n' "$zfs_destroy"
    fi
else
    Fatal 'Trying to delete ZFS pool or filesystem? WTF?' \
            'This is bug, and we definitely do not want that.' \
            'Please report it to https://github.com/zfsnap/zfsnap/issues' \
            'Do not panic, as nothing was deleted. :-)'
fi
