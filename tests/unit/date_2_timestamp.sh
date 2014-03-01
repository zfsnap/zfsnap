#!/bin/sh

. ../spec_helper.sh
. ../../share/zfSnap/core.sh

ItEchos "Date2Timestamp '2014-01-29_02.03.00'" "1390953780"
ItEchos "Date2Timestamp '2013-12-28_22.13.01'" "1388261581"

ExitTests
