#!/bin/sh
# This file is licensed under the BSD-3-Clause license.
# See the AUTHORS and LICENSE files for more information.

. ../spec_helper.sh
. ../../share/zfsnap/core.sh

# These include a TTL delimiter, and should be trimmed accordingly
ItsRetvalIs "TrimToTTL 'zpool@2011-04-05_02.06.00--1y'"                "1y"        0 # pool w/o child w/ snapshot
ItsRetvalIs "TrimToTTL 'z--pool@2011-04-05_02.06.00--1y4d5s'"          "1y4d5s"    0 # TTL delim in poolname w/ snapshot
ItsRetvalIs "TrimToTTL 'z--pool@prefix--2011-04-05_02.06.00--1y4d5s'"  "1y4d5s"    0 # TTL delim in poolname and prefix w/ snapshot
ItsRetvalIs "TrimToTTL 'var@1y--2011-04-05_02.06.00--8m5d32M'"         "8m5d32M"   0 # Prefix is in TTL format with TTL delim
ItsRetvalIs "TrimToTTL 'var@wtf--1y-2011-04-05_02.06.00--2w8d'"        "2w8d"      0 # Prefix is in TTL format with TTL delim
ItsRetvalIs "TrimToTTL 'zpool/child@2010-04-05_02.06.00--1m'"          "1m"        0 # w/ child w/ snapshot
ItsRetvalIs "TrimToTTL 'zpool/child/grandchild@2009-06-08_02.06.00--7y5h'" "7y5h"  0 # w/ grandchild w/ snapshot

# These don't contain a TTL delimiter, and should return an empty string
ItsRetvalIs "TrimToTTL ''"                                             ""          1 # empty
ItsRetvalIs "TrimToTTL 'z--pool'"                                      ""          1 # "pool" is not a valid TTL
ItsRetvalIs "TrimToTTL 'zpool_child'"                                  ""          1 # special character in poolname
ItsRetvalIs "TrimToTTL 'zpool/child'"                                  ""          1 # w/ child w/o snapshot
ItsRetvalIs "TrimToTTL 'zpool/child/grandchild'"                       ""          1 # w/ grandchild w/o snapshot

ExitTests
