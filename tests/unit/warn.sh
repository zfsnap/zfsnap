#!/bin/sh

. ../spec_helper.sh
. ../../zfSnap.sh

ItOutputsStderr "Warn careful" "WARNING: careful"
ItOutputsStderr "Warn 'low space'" "WARNING: low space"

ExitTests
