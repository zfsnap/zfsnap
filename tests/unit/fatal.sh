#!/bin/sh

. ../spec_helper.sh
. ../../zfSnap.sh

ItExitsWith "Fatal 'boom'" 1
ItOutputsStderr "Fatal 'boom'" "FATAL: boom"

ExitTests
