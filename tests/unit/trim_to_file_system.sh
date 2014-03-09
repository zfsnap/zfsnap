#!/bin/sh
# This file is licensed under the BSD-3-Clause license.
# See the AUTHORS and LICENSE files for more information.

. ../spec_helper.sh
. ../../share/zfsnap/core.sh

# These include a snapshot, and should be trimmed accordingly
ItEchos "TrimToFileSystem 'zpool@2011-04-05_02.06.00--1y'"        "zpool"       # pool w/o child w/ snapshot
ItEchos "TrimToFileSystem 'z--pool@2011-04-05_02.06.00--1y'"      "z--pool"     # special characters in poolname w/ snapshot
ItEchos "TrimToFileSystem 'zpool/child@2010-04-05_02.06.00--1m'"  "zpool/child" # w/ child w/ snapshot
ItEchos "TrimToFileSystem 'zpool/child/grandchild@2009-06-08_02.06.00--3d'" "zpool/child/grandchild"   # w/ grandchild w/ snapshot

# These don't contain a snapshot, an should return and empty string
ItEchos "TrimToFileSystem ''"                                     ""            # empty
ItEchos "TrimToFileSystem 'zpool_child'"                          ""            # special character in poolname
ItEchos "TrimToFileSystem 'zpool/child'"                          ""            # w/ child w/o snapshot
ItEchos "TrimToFileSystem 'zpool/child/grandchild'"               ""            # w/ grandchild w/o snapshot

ExitTests
