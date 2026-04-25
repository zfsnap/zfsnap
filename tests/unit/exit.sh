#!/bin/sh

. ../spec_helper.sh
. ../../zfSnap.sh

# test_mode is "true" so Exit should not actually exit
ItReturns "Exit 0" 0
ItReturns "Exit 42" 0
ItReturns "Exit 127" 0

ExitTests
