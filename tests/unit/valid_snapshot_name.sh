#!/bin/sh
# This file is licensed under the BSD-3-Clause license.
# See the AUTHORS and LICENSE files for more information.

. ../spec_helper.sh
. ../../share/zfsnap/core.sh

###
# Valid names
###
# Valid names w/o prefix
PREFIXES=''
ItReturns "ValidSnapshotName '2011-04-05_02.06.00--1y'"              0   # typical snapshot name
ItReturns "ValidSnapshotName '2010-04-05_02.06.00--9y2m3w4d5h6M7s'"  0   # long TTL

# Valid names w/ prefix(es)
PREFIXES='hourly-'
ItReturns "ValidSnapshotName 'hourly-2011-04-05_02.06.00--12d'"      0   # single prefix

PREFIXES='daily--'
ItReturns "ValidSnapshotName 'daily--2011-04-05_02.06.00--56y32w'"   0   # single prefix using TTL delim

PREFIXES='hourly- weekly-'
ItReturns "ValidSnapshotName 'hourly-2011-04-05_02.06.00--1w'"       0   # first prefix w/ two prefixes defined
ItReturns "ValidSnapshotName 'weekly-2011-04-05_02.06.00--19s'"      0   # second prefix w/ two prefixes defined

PREFIXES='hourly- weekly- monthly-'
ItReturns "ValidSnapshotName 'hourly-2011-04-05_02.06.00--3w'"       0   # first prefix w/ three prefixes defined
ItReturns "ValidSnapshotName 'weekly-2011-04-05_02.06.00--6m'"       0   # middle prefix w/ three prefixes defined
ItReturns "ValidSnapshotName 'monthly-2011-04-05_02.06.00--5M'"      0   # last prefix w/ three prefixes defined

###
# Invalid names
###
PREFIXES=''
ItReturns "ValidSnapshotName ''"                                     1   # empty

# Valid in every way except not a selected prefix
PREFIXES=''
ItReturns "ValidSnapshotName 'teal-2011-04-05_02.06.00--1y'"         1   # invalid w/o a prefix defined

PREFIXES='hourly-'
ItReturns "ValidSnapshotName 'orange-2011-04-05_02.06.00--1M'"       1   # invalid w/ one prefix defined

PREFIXES='daily--'
ItReturns "ValidSnapshotName 'purple--2011-04-05_02.06.00--1d'"      1   # invalid w/ one prefix defined using TTL delim

PREFIXES='hourly- weekly-'
ItReturns "ValidSnapshotName 'blue-2011-04-05_02.06.00--1w'"         1   # invalid w/ two prefixes defined

PREFIXES='hourly- weekly- monthly-'
ItReturns "ValidSnapshotName 'black-2011-04-05_02.06.00--1s'"        1   # invalid w/ three prefixes defined

PREFIXES='hourly- weekly- monthly-'
ItReturns "ValidSnapshotName 'zpool/child'"                          1   # filesystem submitted

PREFIXES='hour'
ItReturns "ValidSnapshotName 'hourly-2011-04-05_02.06.00--1y'"       1   # prefixes includes substring of snapshot_prefix

# Valid name; invalid TTL
PREFIXES=''
ItReturns "ValidSnapshotName '2011-04-05_02.06.00--'"                1   # TTL delim without a TTL afterwards
ItReturns "ValidSnapshotName '2010-04-05_02.06.00--45s5y'"           1   # TTL has s before y

# Valid, except the entire pool/fs@snapshot is submitted
ItReturns "ValidSnapshotName 'zpool@2011-04-05_02.06.00--1y'"        1   # pool w/o child w/ snapshot
ItReturns "ValidSnapshotName 'zpool/child@2010-04-05_02.06.00--1m'"  1   # w/ child w/ snapshot

# Outright wrong names
ItReturns "ValidSnapshotName '2014.03.08.1012--1y'"                  1   # date format isn't correct
ItReturns "ValidSnapshotName '2010-04-05_02.06.00'"                  1   # no TTL provided
ItReturns "ValidSnapshotName '--1M'"                                 1   # only TTL provided

PREFIXES='weekly-'
ItReturns "ValidSnapshotName 'weekly--4w'"                           1   # no date provided
ItReturns "ValidSnapshotName 'weekly-'"                              1   # only prefix provided

ExitTests
