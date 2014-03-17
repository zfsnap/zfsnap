#!/bin/sh
# This file is licensed under the BSD-3-Clause license.
# See the AUTHORS and LICENSE files for more information.

. ../spec_helper.sh
. ../../share/zfsnap/core.sh

# These include a TTL delimiter, and should be trimmed accordingly
ItRetvals "TrimToTTL 'zpool@2011-04-05_02.06.00--1y'"                "1y"         # pool w/o child w/ snapshot
ItRetvals "TrimToTTL 'z--pool@2011-04-05_02.06.00--1y4d5s'"          "1y4d5s"     # TTL delim in poolname w/ snapshot
ItRetvals "TrimToTTL 'z--pool@prefix--2011-04-05_02.06.00--1y4d5s'"  "1y4d5s"     # TTL delim in poolname and prefix w/ snapshot
ItRetvals "TrimToTTL 'var@1y--2011-04-05_02.06.00--8m5d32M'"         "8m5d32M"    # Prefix is in TTL format with TTL delim
ItRetvals "TrimToTTL 'zpool/child@2010-04-05_02.06.00--1m'"          "1m"         # w/ child w/ snapshot
ItRetvals "TrimToTTL 'zpool/child/grandchild@2009-06-08_02.06.00--7y5h'" "7y5h"   # w/ grandchild w/ snapshot
# The next one gives us something we don't want, but ValidTTL exists for a reason
ItRetvals "TrimToTTL 'z--pool'"                                      "pool"       # TTL delim in poolname w/o snapshot

# These don't contain a TTL delimiter, and should return an empty string
ItRetvals "TrimToTTL ''"                                             ""           # empty
ItRetvals "TrimToTTL 'zpool_child'"                                  ""           # special character in poolname
ItRetvals "TrimToTTL 'zpool/child'"                                  ""           # w/ child w/o snapshot
ItRetvals "TrimToTTL 'zpool/child/grandchild'"                       ""           # w/ grandchild w/o snapshot

ExitTests
