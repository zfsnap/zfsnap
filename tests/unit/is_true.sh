#!/bin/sh

. ../spec_helper.sh
. ../../zfSnap_lib.sh

ItReturns "IsTrue 'true'"  0
ItReturns "IsTrue 'false'" 1

ExitTests
