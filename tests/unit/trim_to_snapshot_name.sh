#!/bin/sh
# This file is licensed under the BSD-3-Clause license.
# See the AUTHORS and LICENSE files for more information.

. ../spec_helper.sh
. ../../share/zfsnap/core.sh

# These include a snapshot, and should be trimmed accordingly
ItEchos "TrimToSnapshotName 'zpool@2011-04-05_02.06.00--1y'"                  "2011-04-05_02.06.00--1y"         # pool w/o child w/ snapshot
ItEchos "TrimToSnapshotName 'zpool/child@2010-04-05_02.06.00--1m'"            "2010-04-05_02.06.00--1m"         # w/ child w/ snapshot
ItEchos "TrimToSnapshotName 'zpool/child/grandchild@2009-06-08_02.06.00--3d'" "2009-06-08_02.06.00--3d"         # w/ grandchild w/ snapshot
ItEchos "TrimToSnapshotName 'zpool@hourly-2009-06-08_02.06.00--3d'"           "hourly-2009-06-08_02.06.00--3d"  # w/ prefix in snapshot name
ItEchos "TrimToSnapshotName 'zpool@daily--2009-06-08_02.06.00--3d'"           "daily--2009-06-08_02.06.00--3d"  # w/ prefix using TTL delim in snapshot name

# These don't contain a snapshot, and should return an empty string
ItEchos "TrimToSnapshotName ''"                                     ""    # empty
ItEchos "TrimToSnapshotName 'zpool_child'"                          ""    # special character in poolname
ItEchos "TrimToSnapshotName 'zpool/child'"                          ""    # pool w/ child w/o snapshot
ItEchos "TrimToSnapshotName 'zpool/child/grandchild'"               ""    # pool w/ grandchild w/o snapshot
ItEchos "TrimToSnapshotName '2009-06-08_02.06.00--3d'"              ""    # snapshot w/o pool/fs

ExitTests
