#!/bin/sh
# This file is licensed under the BSD-3-Clause license.
# See the AUTHORS and LICENSE files for more information.

. ../spec_helper.sh
. ../../share/zfSnap/core.sh

# These are not snapshots, and should be rejected
ItReturns "IsSnapshot zpool"                                          1   # a zpool
ItReturns "IsSnapshot zpool/child_fs"                                 1   # a filesystem
ItReturns "IsSnapshot zpool/child_fs@"                                1   # no snapshot name provided
ItReturns "IsSnapshot @2011-04-05_02.06.00--1y"                       1   # no zpool/fs supplied
ItReturns "IsSnapshot"                                                1   # empty is not ok

# These are snapshots and should be accepted
ItReturns "IsSnapshot z@2011-04-05_02.06.00--1y"                      0   # single character zpool name w/ snapshot
ItReturns "IsSnapshot zpool@2011-04-05_02.06.00--1y"                  0   # zpool w/ snapshot
ItReturns "IsSnapshot zpool/child_fs@2010-04-05_02.06.00--1m"         0   # zpool's child w/ snapshot
ItReturns "IsSnapshot zpool/child_fs/g_child@2009-06-08_02.06.00--3d" 0   # zpool's grandchild w/ snapshot

ExitTests
