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
PREFIXES=''
SKIP_PREFIX_FILTER='true'
ItsRetvalIs "TrimToSnapshotName 'zpool@npfhourly-2009-06-08_02.06.00--3d'"           "npfhourly-2009-06-08_02.06.00--3d"  0  # ignore prefixes, w/ prefix in snapshot name
ItsRetvalIs "TrimToSnapshotName 'zpool@npfdaily--2009-06-08_02.06.00--3d'"           "npfdaily--2009-06-08_02.06.00--3d"  0  # ignore prefixes, w/ prefix using TTL delim in snapshot name
ItsRetvalIs "TrimToSnapshotName 'npfhourly-2010-04-05_02.06.00--1m'"                 "npfhourly-2010-04-05_02.06.00--1m"  0  # ignore prefixes, snapshot name w/o pool/fs
PREFIXES='pffdaily-- pffhourly-'
SKIP_PREFIX_FILTER='false'
ItsRetvalIs "TrimToSnapshotName 'zpool@pffhourly-2009-06-08_02.06.00--3d'"           "pffhourly-2009-06-08_02.06.00--3d"  0  # explicitly set prefix filtering, w/ prefix in snapshot name
ItsRetvalIs "TrimToSnapshotName 'zpool@pffdaily--2009-06-08_02.06.00--3d'"           "pffdaily--2009-06-08_02.06.00--3d"  0  # explicitly set prefix filtering, w/ prefix using TTL delim in snapshot name
ItsRetvalIs "TrimToSnapshotName 'pffhourly-2010-04-05_02.06.00--1m'"                 "pffhourly-2010-04-05_02.06.00--1m"  0  # explicitly set prefix filtering, snapshot name w/o pool/fs

# These don't contain a snapshot, and should return an empty string
PREFIXES=''
SKIP_PREFIX_FILTER=''
ItsRetvalIs "TrimToSnapshotName ''"                                     ""  1  # empty
ItsRetvalIs "TrimToSnapshotName 'zpool_child'"                          ""  1  # special character in poolname
ItsRetvalIs "TrimToSnapshotName 'zpool/child'"                          ""  1  # pool w/ child w/o snapshot
ItsRetvalIs "TrimToSnapshotName 'zpool/child/grandchild'"               ""  1  # pool w/ grandchild w/o snapshot
ItsRetvalIs "TrimToSnapshotName 'zpool@daily--2009-06-08_02.06.00--3d'" ""  1  # w/ invalid prefix
SKIP_PREFIX_FILTER='false'
ItsRetvalIs "TrimToSnapshotName 'zpool@pffdaily--2009-06-08_02.06.00--3d'" ""  1  # w/ invalid prefix, explicitly set prefix filtering

ExitTests
