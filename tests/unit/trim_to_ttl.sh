#!/bin/sh
# This file is licensed under the BSD-3-Clause license.
# See the AUTHORS and LICENSE files for more information.

. ../spec_helper.sh
. ../../share/zfsnap/core.sh

# These include a TTL delimiter, and should be trimmed accordingly
ItEchos "TrimToTTL 'zpool@2011-04-05_02.06.00--1y'"                "1y"         # pool w/o child w/ snapshot
ItEchos "TrimToTTL 'z--pool@2011-04-05_02.06.00--1y4d5s'"          "1y4d5s"     # TTL delim in poolname w/ snapshot
ItEchos "TrimToTTL 'z--pool@prefix--2011-04-05_02.06.00--1y4d5s'"  "1y4d5s"     # TTL delim in poolname and prefix w/ snapshot
ItEchos "TrimToTTL 'var@1y--2011-04-05_02.06.00--8m5d32M'"         "8m5d32M"    # Prefix is in TTL format with TTL delim
ItEchos "TrimToTTL 'zpool/child@2010-04-05_02.06.00--1m'"          "1m"         # w/ child w/ snapshot
ItEchos "TrimToTTL 'zpool/child/grandchild@2009-06-08_02.06.00--7y5h'" "7y5h"   # w/ grandchild w/ snapshot
# The next one gives us something we don't want, but ValidTTL exists for a reason
ItEchos "TrimToTTL 'z--pool'"                                      "pool"       # TTL delim in poolname w/o snapshot

# These don't contain a TTL delimiter, and should return an empty string
ItEchos "TrimToTTL ''"                                             ""           # empty
ItEchos "TrimToTTL 'zpool_child'"                                  ""           # special character in poolname
ItEchos "TrimToTTL 'zpool/child'"                                  ""           # w/ child w/o snapshot
ItEchos "TrimToTTL 'zpool/child/grandchild'"                       ""           # w/ grandchild w/o snapshot

ExitTests
