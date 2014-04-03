#!/bin/sh
# This file is licensed under the BSD-3-Clause license.
# See the AUTHORS and LICENSE files for more information.

. ../spec_helper.sh
. ../../share/zfSnap/core.sh

ItReturns "IsTrue 'true'"  0
ItReturns "IsTrue 'false'" 1

ExitTests
