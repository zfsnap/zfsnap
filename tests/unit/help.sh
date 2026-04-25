#!/bin/sh

. ../spec_helper.sh
. ../../zfSnap.sh

# Help should exit 0 (captured in subshell since test_mode=true)
ItExitsWith "Help" 0
ItOutputsStdout "Help" "zfSnap"
ItOutputsStdout "Help" "GENERIC OPTIONS"
ItOutputsStdout "Help" "OPTIONS"

ExitTests
