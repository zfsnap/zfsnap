#!/bin/sh
# This file is licensed under the BSD-3-Clause license.
# See the AUTHORS and LICENSE files for more information.

. ../spec_helper.sh
. ../../share/zfsnap/core.sh

# These are leap years
ItReturns "IsLeapYear 2004"         0   #
ItReturns "IsLeapYear 2008"         0   #
ItReturns "IsLeapYear 2012"         0   #
ItReturns "IsLeapYear 2016"         0   #
ItReturns "IsLeapYear 2020"         0   #
ItReturns "IsLeapYear 2024"         0   #
ItReturns "IsLeapYear 2396"         0   # far in the future

# These are leap year exceptions
ItReturns "IsLeapYear 2000"         0   # / 400
ItReturns "IsLeapYear 2400"         0   # / 400
ItReturns "IsLeapYear 2100"         1   # / 100 !/ 400
ItReturns "IsLeapYear 1900"         1   # / 100 !/ 400
ItReturns "IsLeapYear"              1   # empty is not ok

# These are not leap years
ItReturns "IsLeapYear 1999"         1   #
ItReturns "IsLeapYear 2011"         1   #
ItReturns "IsLeapYear 2013"         1   #
ItReturns "IsLeapYear 2017"         1   #
ItReturns "IsLeapYear 2121"         1   # far in the future

# invalid input
ItReturns "IsLeapYear Chicago"      1   # great band, but not a leap year

ExitTests
