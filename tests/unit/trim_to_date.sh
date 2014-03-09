#!/bin/sh
# This file is licensed under the BSD-3-Clause license.
# See the AUTHORS and LICENSE files for more information.

. ../spec_helper.sh
. ../../share/zfsnap/core.sh

# These include a date matching the "date pattern", and should be trimmed accordingly
ItEchos "TrimToDate 'zpool@2009-04-05_23.32.00--1y'"        "2009-04-05_23.32.00"   # a full dataset name
ItEchos "TrimToDate '2011-04-05_23.32.00--1y'"              "2011-04-05_23.32.00"   # snapshot name
ItEchos "TrimToDate '2014-01-29_04.59.00--1y54m2w4d5s'"     "2014-01-29_04.59.00"   # long TTL
ItEchos "TrimToDate 'hourly-2010-04-30_12.16.00--5M'"       "2010-04-30_12.16.00"   # w/ prefix
ItEchos "TrimToDate 'daily--2010-12-30_01.02.00--12w'"      "2010-12-30_01.02.00"   # w/ prefix including TTL delimiter
ItEchos "TrimToDate '2013-08-14_14.02.00'"                  "2013-08-14_14.02.00"   # only date submitted
ItEchos "TrimToDate 'zpool@2004-04-05_23.32.00--2008-01-05_23.32.00--1y'"  "2008-01-05_23.32.00"   # an asshole uses a date in the prefix

# These do not include a date matching the "date pattern", and should return an empty string
ItEchos "TrimToDate '201-04-05_23.32.00--1y'"               ""            # year has 3 characters
ItEchos "TrimToDate '2001-34-05_23.32.00--1y'"              ""            # month is invalid
ItEchos "TrimToDate '2014.03.05.0924'"                      ""            # wrong date format

ItEchos "TrimToDate ''"                                     ""            # empty
ItEchos "TrimToDate 'zpool_child'"                          ""            # special character in poolname
ItEchos "TrimToDate 'zpool/child'"                          ""            # w/ child w/o snapshot
ItEchos "TrimToDate 'zpool/child/grandchild'"               ""            # w/ grandchild w/o snapshot

ExitTests
