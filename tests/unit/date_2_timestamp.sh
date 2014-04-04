#!/bin/sh
# This file is licensed under the BSD-3-Clause license.
# See the AUTHORS and LICENSE files for more information.

. ../spec_helper.sh
. ../../share/zfsnap/core.sh

ItEchos "Date2Timestamp '2014-01-29_02.03.00'" "1390953780"
ItEchos "Date2Timestamp '2013-12-28_22.13.01'" "1388261581"

ExitTests
