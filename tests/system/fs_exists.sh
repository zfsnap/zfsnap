#!/bin/sh
# This file is licensed under the BSD-3-Clause license.
# See the AUTHORS and LICENSE files for more information.

. ../spec_helper.sh
. ../../share/zfsnap/core.sh

zfsnap='../../sbin/zfsnap.sh'
zfs=`which zfs`

DATASET="$TEST_POOL/$TEST_DATASET"

TEST_DATE="2025-02-18_17.01.35"

# These FSs exist and should be accepted.
ItReturns "FSExists tpool"                             0   # top level zpool
ItReturns "FSExists tpool/subds1"                      0   # zpool w/ child

# These FSs do not exist and should be rejected.
ItReturns "FSExists tpool/subds1_fs"                   1   # similar child name
ItReturns "FSExists tpool/subds1_fs/grandchild"        1   # similar child name w/ grandchild
ItReturns "FSExists"                                   1   # empty is not ok

ExitTests
