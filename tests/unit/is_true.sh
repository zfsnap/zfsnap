#!/bin/sh

. ../spec_helper.sh
. ../../share/zfSnap/core.sh

ItReturns "IsTrue 'true'"  0
ItReturns "IsTrue 'false'" 1

ExitTests
