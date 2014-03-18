#!/bin/sh
# This file is licensed under the BSD-3-Clause license.
# See the AUTHORS and LICENSE files for more information.

. ../spec_helper.sh
. ../../share/zfsnap/core.sh

# These contain a valid pool, and should be trimmed accordingly
POOLS='zpool logs var z--pool'
ItRetvals "TrimToPool 'zpool'"                                "zpool"             # w/ child w/o snapshot
ItRetvals "TrimToPool 'logs/child'"                           "logs"              # w/ child w/o snapshot
ItRetvals "TrimToPool 'var/child/grandchild'"                 "var"               # w/ grandchild w/o snapshot
ItRetvals "TrimToPool 'zpool/child/grandchild'"               "zpool"             # w/ grandchild w/o snapshot
ItRetvals "TrimToPool 'zpool@2011-04-05_02.06.00--1y'"        "zpool"             # pool w/o child w/ snapshot
ItRetvals "TrimToPool 'z--pool@2011-04-05_02.06.00--1y'"      "z--pool"           # special characters in poolname w/ snapshot
ItRetvals "TrimToPool 'zpool/child@2010-04-05_02.06.00--1m'"  "zpool"             # w/ child w/ snapshot
ItRetvals "TrimToPool 'zpool/child/grandchild@2009-06-08_02.06.00--3d'" "zpool"   # w/ grandchild w/ snapshot

# These don't contain a valid pool, and should return an empty string
ItRetvals "TrimToPool ''"                                     ""                  # empty
ItRetvals "TrimToPool 'zpool_fake'"                           ""                  # special character in poolname

ExitTests
