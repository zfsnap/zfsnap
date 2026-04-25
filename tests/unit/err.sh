#!/bin/sh

. ../spec_helper.sh
. ../../zfSnap.sh

ItOutputsStderr "Err something" "ERROR: something"
ItOutputsStderr "Err 'disk full'" "ERROR: disk full"

ExitTests
