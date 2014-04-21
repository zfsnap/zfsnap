#!/bin/sh
# This file is licensed under the BSD-3-Clause license.
# See the AUTHORS and LICENSE files for more information.

. ../spec_helper.sh
. ../../share/zfsnap/core.sh

# Easy additions
ItsRetvalIs "DatePlusTTL '2011-12-05_02.06.00' '1s'"         "2011-12-05_02.06.01"    0  # 1 second
ItsRetvalIs "DatePlusTTL '2009-01-31_10.11.00' '1M'"         "2009-01-31_10.12.00"    0  # 1 minute
ItsRetvalIs "DatePlusTTL '2014-04-01_12.00.00' '1h'"         "2014-04-01_13.00.00"    0  # 1 hour
ItsRetvalIs "DatePlusTTL '2010-12-21_18.36.55' '1d'"         "2010-12-22_18.36.55"    0  # 1 day
ItsRetvalIs "DatePlusTTL '2008-08-01_00.00.00' '1w'"         "2008-08-08_00.00.00"    0  # 1 week
ItsRetvalIs "DatePlusTTL '2007-05-01_23.59.00' '1m'"         "2007-06-01_23.59.00"    0  # 1 month
ItsRetvalIs "DatePlusTTL '2013-11-04_06.06.06' '1y'"         "2014-11-04_06.06.06"    0  # 1 year

# Test for sh arithmetic treating 0-padded numbers as octal
ItsRetvalIs "DatePlusTTL '2011-04-05_02.06.09' '8s'"         "2011-04-05_02.06.17"    0  #

# Additions with roll-over
ItsRetvalIs "DatePlusTTL '2011-04-05_02.06.34' '56s'"        "2011-04-05_02.07.30"    0  #
ItsRetvalIs "DatePlusTTL '2011-04-05_02.06.00' '94M'"        "2011-04-05_03.40.00"    0  #
ItsRetvalIs "DatePlusTTL '2011-04-05_02.06.00' '43h'"        "2011-04-06_21.06.00"    0  #
ItsRetvalIs "DatePlusTTL '2011-04-05_02.06.00' '55d'"        "2011-05-30_02.06.00"    0  #
ItsRetvalIs "DatePlusTTL '2011-04-05_02.06.00' '4w' "        "2011-05-03_02.06.00"    0  #
ItsRetvalIs "DatePlusTTL '2011-04-05_02.06.00' '18m'"        "2012-10-05_02.06.00"    0  #
ItsRetvalIs "DatePlusTTL '2011-04-05_02.06.00' '15y'"        "2026-04-05_02.06.00"    0  #

# Leap year additions
ItsRetvalIs "DatePlusTTL '2008-02-27_01.05.00' '2d'"         "2008-02-29_01.05.00"    0  #
ItsRetvalIs "DatePlusTTL '2012-02-27_01.05.00' '3d'"         "2012-03-01_01.05.00"    0  #
ItsRetvalIs "DatePlusTTL '2011-02-27_01.05.00' '2d'"         "2011-03-01_01.05.00"    0  #
ItsRetvalIs "DatePlusTTL '2012-01-30_01.05.00' '6w'"         "2012-03-12_01.05.00"    0  #
ItsRetvalIs "DatePlusTTL '2015-12-30_01.05.00' '71d'"        "2016-03-10_01.05.00"    0  #
ItsRetvalIs "DatePlusTTL '2011-01-04_03.00.00' '4y'"         "2015-01-04_03.00.00"    0  # 4 years
ItsRetvalIs "DatePlusTTL '2015-01-04_03.00.00' '1460d'"      "2019-01-03_03.00.00"    0  # 4 years in days
ItsRetvalIs "DatePlusTTL '2007-01-04_03.00.00' '126144000s'" "2011-01-03_03.00.00"    0  # 4 years in seconds

# Man page examples
ItsRetvalIs "DatePlusTTL '2009-02-27_00.00.00' '1m3d'"       "2009-03-30_00.00.00"    0  #
ItsRetvalIs "DatePlusTTL '2009-10-31_00.00.00' '1m'"         "2009-12-01_00.00.00"    0  # October is longer than November

# Test range edges
ItsRetvalIs "DatePlusTTL '2014-09-03_22.58.52' '3m4w1h1M7s'" "2014-12-31_23.59.59"    0  # Don't roll over
ItsRetvalIs "DatePlusTTL '2015-11-20_06.00.59' '60119M'"     "2015-12-31_23.59.59"    0  # Roll, to a limit
ItsRetvalIs "DatePlusTTL '2015-11-20_06.00.59' '60119M1s'"   "2016-01-01_00.00.00"    0  # Roll over the limit
ItsRetvalIs "DatePlusTTL '2007-01-02_00.00.00' '126143999s'" "2010-12-31_23.59.59"    0  # 1 short of 4 years in seconds through a leap year

# Invalid TTL
ItsRetvalIs "DatePlusTTL '2007-01-02_00.00.00' 'fake'"       ""                       1  # Shouldn't happen, but worth testing.

ExitTests
