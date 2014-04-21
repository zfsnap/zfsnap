#!/bin/sh
# This file is licensed under the BSD-3-Clause license.
# See the AUTHORS and LICENSE files for more information.

. ../spec_helper.sh
. ../../share/zfsnap/core.sh

# These contain a valid pool, and should be trimmed accordingly
POOLS='zpool logs var z--pool'
ItsRetvalIs "TrimToPool 'zpool'"                                "zpool"            0  # w/ child w/o snapshot
ItsRetvalIs "TrimToPool 'logs/child'"                           "logs"             0  # w/ child w/o snapshot
ItsRetvalIs "TrimToPool 'var/child/grandchild'"                 "var"              0  # w/ grandchild w/o snapshot
ItsRetvalIs "TrimToPool 'zpool/child/grandchild'"               "zpool"            0  # w/ grandchild w/o snapshot
ItsRetvalIs "TrimToPool 'zpool@2011-04-05_02.06.00--1y'"        "zpool"            0  # pool w/o child w/ snapshot
ItsRetvalIs "TrimToPool 'z--pool@2011-04-05_02.06.00--1y'"      "z--pool"          0  # special characters in poolname w/ snapshot
ItsRetvalIs "TrimToPool 'zpool/child@2010-04-05_02.06.00--1m'"  "zpool"            0  # w/ child w/ snapshot
ItsRetvalIs "TrimToPool 'zpool/child/grandchild@2009-06-08_02.06.00--3d'" "zpool"  0  # w/ grandchild w/ snapshot

# These don't contain a valid pool, and should return an empty string
ItsRetvalIs "TrimToPool ''"                                     ""                 1  # empty
ItsRetvalIs "TrimToPool 'zpool_fake'"                           ""                 1  # special character in poolname

ExitTests
