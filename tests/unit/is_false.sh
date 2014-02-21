#!/bin/sh

. ../spec_helper.sh
. ../../zfSnap_lib.sh

ItReturns "IsFalse 'false'" 0
ItReturns "IsFalse 'true'"  1

ExitTests
