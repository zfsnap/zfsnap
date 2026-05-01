#!/bin/sh
# This file is licensed under the BSD-3-Clause license.
# See the AUTHORS and LICENSE files for more information.

. ../spec_helper.sh
. ../../share/zfsnap/core.sh

# Override the FSExists function for unit tests
FSExists() {
    FS_LIST='zpool
z--pool
zpool/child
zpool/child/grandchild
data/archive'

    local i
    for i in $FS_LIST; do
        [ "$1" = "$i" ] && return 0
    done

    return 1
}

# These include a snapshot, and should be trimmed accordingly

ItsRetvalIs "TrimToFileSystem 'zpool'"                                "zpool"                  0  # pool
ItsRetvalIs "TrimToFileSystem 'data/archive'"                         "data/archive"           0  # pool w/ child
ItsRetvalIs "TrimToFileSystem 'zpool/child/grandchild'"               "zpool/child/grandchild" 0  # pool w/ grandchild
ItsRetvalIs "TrimToFileSystem 'zpool@2011-04-05_02.06.00--1y'"        "zpool"                  0  # pool  w/ snapshot
ItsRetvalIs "TrimToFileSystem 'z--pool@2011-04-05_02.06.00--1y'"      "z--pool"                0  # ttl delim in poolname w/ snapshot
ItsRetvalIs "TrimToFileSystem 'zpool/child@2010-04-05_02.06.00--1m'"  "zpool/child"            0  # w/ child w/ snapshot
ItsRetvalIs "TrimToFileSystem 'zpool/child/grandchild@2009-06-08_02.06.00--3d'" "zpool/child/grandchild"  0  # w/ grandchild w/ snapshot

# These don't contain a snapshot, an should return and empty string
ItsRetvalIs "TrimToFileSystem ''"                                     ""  1          # empty
ItsRetvalIs "TrimToFileSystem 'fake_zpool'"                           ""  1          # non-existant FS
ItsRetvalIs "TrimToFileSystem 'fake_zpool/child'"                     ""  1          # non-existant FS w/ child w/o snapshot
ItsRetvalIs "TrimToFileSystem 'fake_zpool/child/grandchild'"          ""  1          # non-existant FS w/ grandchild w/o snapshot

ExitTests
