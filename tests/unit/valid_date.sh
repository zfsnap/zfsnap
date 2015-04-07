#!/bin/sh
# This file is licensed under the BSD-3-Clause license.
# See the AUTHORS and LICENSE files for more information.

. ../spec_helper.sh
. ../../share/zfsnap/core.sh

# First date is greater, and should return 0
ItReturns "ValidDate 2012-04-08_12.34.54"   0   #
ItReturns "ValidDate 2010-12-02_00.15.00"   0   #
ItReturns "ValidDate 2009-01-31_23.01.24"   0   #
ItReturns "ValidDate 2014-03-17_17.00.00"   0   #
ItReturns "ValidDate 2013-07-22_08.59.59"   0   #
ItReturns "ValidDate 2011-10-10_10.10.11"   0   #
ItReturns "ValidDate 2012-02-29_04.29.00"   0   #
ItReturns "ValidDate 2010-04-08_12.34.54"   0   #
ItReturns "ValidDate 1962-02-14_04.22.22"   0   # 1900s
ItReturns "ValidDate 2001-07-02_21.22.32"   0   # 
ItReturns "ValidDate 2040-11-04_08.30.24"   0   # year 2038

ItReturns "ValidDate '2040-11-04_08.30.24 2010-04-08_12.34.54'"   1   # two valid dates
ItReturns "ValidDate 2001-07-02 21.22.32"   1   # space in date
ItReturns "ValidDate 2012.02.29_04-29-00"   1   # special characters in wrong place
ItReturns "ValidDate electric_slide"        1   # invalid in every way
ItReturns "ValidDate ' '"                   1   #
ItReturns "ValidDate"                       1   #

ExitTests
