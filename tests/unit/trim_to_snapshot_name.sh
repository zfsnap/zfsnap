#!/bin/sh
# This file is licensed under the BSD-3-Clause license.
# See the AUTHORS and LICENSE files for more information.

. ../spec_helper.sh
. ../../share/zfsnap/core.sh

# These include a snapshot, and should be trimmed accordingly
PREFIXES=''
ItRetvals "TrimToSnapshotName 'zpool@2011-04-05_02.06.00--1y'"                  "2011-04-05_02.06.00--1y"         0  # pool w/o child w/ snapshot
ItRetvals "TrimToSnapshotName 'zpool/child@2010-04-05_02.06.00--1m'"            "2010-04-05_02.06.00--1m"         0  # w/ child w/ snapshot
ItRetvals "TrimToSnapshotName 'zpool/child/grandchild@2009-06-08_02.06.00--3d'" "2009-06-08_02.06.00--3d"         0  # w/ grandchild w/ snapshot
PREFIXES='daily-- hourly-'
ItRetvals "TrimToSnapshotName 'zpool@hourly-2009-06-08_02.06.00--3d'"           "hourly-2009-06-08_02.06.00--3d"  0  # w/ prefix in snapshot name
ItRetvals "TrimToSnapshotName 'zpool@daily--2009-06-08_02.06.00--3d'"           "daily--2009-06-08_02.06.00--3d"  0  # w/ prefix using TTL delim in snapshot name
ItRetvals "TrimToSnapshotName 'hourly-2010-04-05_02.06.00--1m'"                 "hourly-2010-04-05_02.06.00--1m"  0  # snapshot name w/o pool/fs
PREFIXES=''
ItRetvals "TrimToSnapshotName '2009-06-08_02.06.00--3d'"                        "2009-06-08_02.06.00--3d"         0  # snapshot name w/o pool/fs

# These don't contain a snapshot, and should return an empty string
PREFIXES=''
ItRetvals "TrimToSnapshotName ''"                                     ""  1  # empty
ItRetvals "TrimToSnapshotName 'zpool_child'"                          ""  1  # special character in poolname
ItRetvals "TrimToSnapshotName 'zpool/child'"                          ""  1  # pool w/ child w/o snapshot
ItRetvals "TrimToSnapshotName 'zpool/child/grandchild'"               ""  1  # pool w/ grandchild w/o snapshot
ItRetvals "TrimToSnapshotName 'zpool@daily--2009-06-08_02.06.00--3d'" ""  1  # w/ invalid prefix

ExitTests
