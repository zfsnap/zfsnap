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
ItRetvals "TrimToFileSystem 'zpool'"                                "zpool"                  0  # pool
ItRetvals "TrimToFileSystem 'data/archive'"                         "data/archive"           0  # pool w/ child
ItRetvals "TrimToFileSystem 'zpool/child/grandchild'"               "zpool/child/grandchild" 0  # pool w/ grandchild
ItRetvals "TrimToFileSystem 'zpool@2011-04-05_02.06.00--1y'"        "zpool"                  0  # pool  w/ snapshot
ItRetvals "TrimToFileSystem 'z--pool@2011-04-05_02.06.00--1y'"      "z--pool"                0  # ttl delim in poolname w/ snapshot
ItRetvals "TrimToFileSystem 'zpool/child@2010-04-05_02.06.00--1m'"  "zpool/child"            0  # w/ child w/ snapshot
ItRetvals "TrimToFileSystem 'zpool/child/grandchild@2009-06-08_02.06.00--3d'" "zpool/child/grandchild"  0  # w/ grandchild w/ snapshot

# These don't contain a snapshot, an should return and empty string
ItRetvals "TrimToFileSystem ''"                                     ""  1          # empty
ItRetvals "TrimToFileSystem 'fake_zpool'"                           ""  1          # non-existant FS
ItRetvals "TrimToFileSystem 'fake_zpool/child'"                     ""  1          # non-existant FS w/ child w/o snapshot
ItRetvals "TrimToFileSystem 'fake_zpool/child/grandchild'"          ""  1          # non-existant FS w/ grandchild w/o snapshot

ExitTests
