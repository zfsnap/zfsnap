#!/bin/sh

. ../spec_helper.sh
. ../../share/zfSnap/core.sh

# These should match, and thus be rejected
SKIP_POOLS=' kit_pool karr_pool knight_pool'
ItReturns "SkipPool knight_pool/child_fs@2011-04-05_02.06.00--1m"   1   # with child FS

SKIP_POOLS=' kit_pool karr_pool knight_pool'
ItReturns "SkipPool karr_pool@2012-09-04_02.06.00--1d"              1   # middle entry

SKIP_POOLS=' kit_pool'
ItReturns "SkipPool kit_pool@2011-09-04_02.06.00--5y"               1   # single pool


# These should not match, and thus be accepted
SKIP_POOLS=' kit_pool karr_pool knight_pool'
ItReturns "SkipPool michael_pool@child_fs@2011-04-05_02.06.00--1m"  0   # multiple pools & child FS

SKIP_POOLS=' kit_pool'
ItReturns "SkipPool michael_pool@2012-09-04_02.02.00--1d1s"         0   # single pool in list

SKIP_POOLS=''
ItReturns "SkipPool karr_pool@2012-09-04_02.02.00--1y"              0   # empty pool list

ExitTests
