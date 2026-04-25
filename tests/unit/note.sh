#!/bin/sh

. ../spec_helper.sh
. ../../zfSnap.sh

ItOutputsStderr "Note hello" "NOTE: hello"
ItOutputsStderr "Note 'multiple words here'" "NOTE: multiple words here"

ExitTests
