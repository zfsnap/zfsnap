#!/bin/sh
# This file is licensed under the BSD-3-Clause license.
# See the AUTHORS and LICENSE files for more information.

. ../spec_helper.sh
. ../../share/zfsnap/core.sh

# These include a snapshot, and should be trimmed accordingly
PREFIXES=''
ItsRetvalIs "TrimToSnapshotName 'zpool@2011-04-05_02.06.00--1y'"                  "2011-04-05_02.06.00--1y"         0  # pool w/o child w/ snapshot
ItsRetvalIs "TrimToSnapshotName 'zpool/child@2010-04-05_02.06.00--1m'"            "2010-04-05_02.06.00--1m"         0  # w/ child w/ snapshot
ItsRetvalIs "TrimToSnapshotName 'zpool/child/grandchild@2009-06-08_02.06.00--3d'" "2009-06-08_02.06.00--3d"         0  # w/ grandchild w/ snapshot
PREFIXES='daily-- hourly-'
ItsRetvalIs "TrimToSnapshotName 'zpool@hourly-2009-06-08_02.06.00--3d'"           "hourly-2009-06-08_02.06.00--3d"  0  # w/ prefix in snapshot name
ItsRetvalIs "TrimToSnapshotName 'zpool@daily--2009-06-08_02.06.00--3d'"           "daily--2009-06-08_02.06.00--3d"  0  # w/ prefix using TTL delim in snapshot name
ItsRetvalIs "TrimToSnapshotName 'hourly-2010-04-05_02.06.00--1m'"                 "hourly-2010-04-05_02.06.00--1m"  0  # snapshot name w/o pool/fs
PREFIXES=''
ItsRetvalIs "TrimToSnapshotName '2009-06-08_02.06.00--3d'"                        "2009-06-08_02.06.00--3d"         0  # snapshot name w/o pool/fs
ItsRetvalIs "TrimToSnapshotName '2009-06-08_02.06.00--forever'"                   "2009-06-08_02.06.00--forever"    0  # forever TTL
PREFIXES='wtf- 2004-04-05_23.32.00--'
ItsRetvalIs "TrimToSnapshotName 'z@2004-04-05_23.32.00--2008-01-05_23.32.00--1y'" "2004-04-05_23.32.00--2008-01-05_23.32.00--1y"  0  # an idiot/asshat uses date and TTL delim in the prefix
PREFIXES='wtf--1y- wtf--6M-'
ItsRetvalIs "TrimToSnapshotName 'z@wtf--6M-2008-01-05_23.32.00--1y'"              "wtf--6M-2008-01-05_23.32.00--1y" 0  # an idiot/asshat uses TTL w/ delim in the prefix

# These don't contain a snapshot, and should return an empty string
PREFIXES=''
ItsRetvalIs "TrimToSnapshotName ''"                                     ""  1  # empty
ItsRetvalIs "TrimToSnapshotName 'zpool_child'"                          ""  1  # special character in poolname
ItsRetvalIs "TrimToSnapshotName 'zpool/child'"                          ""  1  # pool w/ child w/o snapshot
ItsRetvalIs "TrimToSnapshotName 'zpool/child/grandchild'"               ""  1  # pool w/ grandchild w/o snapshot
ItsRetvalIs "TrimToSnapshotName 'zpool@daily--2009-06-08_02.06.00--3d'" ""  1  # w/ invalid prefix

ExitTests
