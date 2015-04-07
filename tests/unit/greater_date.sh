#!/bin/sh
# This file is licensed under the BSD-3-Clause license.
# See the AUTHORS and LICENSE files for more information.

. ../spec_helper.sh
. ../../share/zfsnap/core.sh

# First date is greater, and should return 0
ItReturns "GreaterDate 2012-04-08_12.34.54 2011-04-08_12.34.54"   0   # one year greater
ItReturns "GreaterDate 2010-12-02_00.15.00 2010-11-02_00.15.00"   0   # one month greater
ItReturns "GreaterDate 2009-01-31_23.01.24 2009-01-30_23.01.24"   0   # one day greater
ItReturns "GreaterDate 2014-03-17_17.00.00 2014-03-17_16.00.00"   0   # one hour greater
ItReturns "GreaterDate 2013-07-22_08.59.59 2013-07-22_08.58.59"   0   # one minute greater
ItReturns "GreaterDate 2011-10-10_10.10.11 2011-10-10_10.10.10"   0   # one second greater
ItReturns "GreaterDate 2012-02-29_04.29.00 2012-02-28_04.29.00"   0   # leap day
ItReturns "GreaterDate 2010-04-08_12.34.54 2009-09-10_14.54.58"   0   # complex-ly greater
ItReturns "GreaterDate 1962-02-14_04.22.22 1959-07-25_09.00.00"   0   # 1900s
ItReturns "GreaterDate 2001-07-02_21.22.32 1998-09-05_19.44.15"   0   # across millennium

# Same date
ItReturns "GreaterDate 2015-11-04_08.35.09 2015-11-04_08.35.09"   0   # Same date

# Second date is greater, and should return 1
ItReturns "GreaterDate 2011-04-08_12.34.54 2012-04-08_12.34.54"   1   # one year less
ItReturns "GreaterDate 2010-11-02_00.15.00 2010-12-02_00.15.00"   1   # one month less
ItReturns "GreaterDate 2009-01-30_23.01.24 2009-01-31_23.01.24"   1   # one day less
ItReturns "GreaterDate 2014-03-17_16.00.00 2014-03-17_17.00.00"   1   # one hour less
ItReturns "GreaterDate 2013-07-22_08.58.59 2013-07-22_08.59.59"   1   # one minute less
ItReturns "GreaterDate 2011-10-10_10.10.10 2011-10-10_10.10.11"   1   # one second less
ItReturns "GreaterDate 2012-02-28_04.29.00 2012-02-29_04.29.00"   1   # leap day
ItReturns "GreaterDate 2009-09-10_14.54.58 2010-04-08_12.34.54"   1   # complex-ly less
ItReturns "GreaterDate 1969-02-14_04.22.22 1987-07-25_09.00.00"   1   # 1900s
ItReturns "GreaterDate 1977-04-01_14.54.58 2030-01-04_12.34.54"   1   # across millennium

# Y2038 compatibility
ItReturns "GreaterDate 2005-12-20_10.29.22 2040-11-04_08.30.24"   1   #

# Invalid input
ItReturns "GreaterDate 1977-04-01 14.54.58 2030-01-04_12.34.54"   2   # space in the date
ItReturns "GreaterDate murple 2030-01-04_12.34.54"                2   #
ItReturns "GreaterDate 2030-01-04_12.34.54 lmnop"                 2   #

ExitTests
