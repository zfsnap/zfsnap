#!/bin/sh

. ../spec_helper.sh
. ../../share/zfSnap/core.sh

ItReturns "IsFalse 'false'" 0
ItReturns "IsFalse 'true'"  1

ExitTests
