#!/bin/sh
# This file is licensed under the BSD-3-Clause license.
# See the AUTHORS and LICENSE files for more information.

. ../spec_helper.sh
. ../../share/zfsnap/core.sh

# These FSs exist and should be accepted.
FS_LIST='zpool
zpool/child
zpool/child/grandchild
var/log
tank/Knight_Rider'

ItReturns "FSExists zpool"                             0   # top level zpool
ItReturns "FSExists zpool/child"                       0   # zpool w/ child
ItReturns "FSExists zpool/child/grandchild"            0   # zpool w/ grandchild
ItReturns "FSExists var/log"                           0   # other name with child
ItReturns "FSExists tank/Knight_Rider"                 0   # another name with child

# These FSs do not exist and should be rejected.
ItReturns "FSExists zpool/child_fs"                    1   # similar child name
ItReturns "FSExists zpool/child_fs/grandchild"         1   # similar child name w/ grandchild
ItReturns "FSExists var/log/"                          1   # trailing / isn't allowed
ItReturns "FSExists"                                   1   # empty is not ok

ExitTests
