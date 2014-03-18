#!/bin/sh
# This file is licensed under the BSD-3-Clause license.
# See the AUTHORS and LICENSE files for more information.

. ../spec_helper.sh
. ../../share/zfsnap/core.sh

# These include a snapshot, and should be trimmed accordingly
FS_LIST='zpool
z--pool
zpool/child
zpool/child/grandchild
data/archive'
ItRetvals "TrimToFileSystem 'zpool'"                                "zpool"        # pool
ItRetvals "TrimToFileSystem 'data/archive'"                         "data/archive" # pool w/ child
ItRetvals "TrimToFileSystem 'zpool/child/grandchild'"               "zpool/child/grandchild" # pool w/ grandchild
ItRetvals "TrimToFileSystem 'zpool@2011-04-05_02.06.00--1y'"        "zpool"        # pool  w/ snapshot
ItRetvals "TrimToFileSystem 'z--pool@2011-04-05_02.06.00--1y'"      "z--pool"      # ttl delim in poolname w/ snapshot
ItRetvals "TrimToFileSystem 'zpool/child@2010-04-05_02.06.00--1m'"  "zpool/child"  # w/ child w/ snapshot
ItRetvals "TrimToFileSystem 'zpool/child/grandchild@2009-06-08_02.06.00--3d'" "zpool/child/grandchild"   # w/ grandchild w/ snapshot

# These don't contain a snapshot, an should return and empty string
ItRetvals "TrimToFileSystem ''"                                     ""             # empty
ItRetvals "TrimToFileSystem 'fake_zpool'"                           ""             # non-existant FS
ItRetvals "TrimToFileSystem 'fake_zpool/child'"                     ""             # non-existant FS w/ child w/o snapshot
ItRetvals "TrimToFileSystem 'fake_zpool/child/grandchild'"          ""             # non-existant FS w/ grandchild w/o snapshot

ExitTests
