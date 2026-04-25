#!/bin/sh

. ../spec_helper.sh
. ../../zfSnap.sh

# Compute expected timestamps dynamically so tests pass in any timezone.
expected_1=$(date -d "2014-01-29 02:03:00" '+%s' 2>/dev/null || date -j -f '%Y-%m-%d %H.%M.%S' '2014-01-29 02.03.00' '+%s' 2>/dev/null)
expected_2=$(date -d "2013-12-28 22:13:01" '+%s' 2>/dev/null || date -j -f '%Y-%m-%d %H.%M.%S' '2013-12-28 22.13.01' '+%s' 2>/dev/null)

ItEchos "Date2Timestamp '2014-01-29_02.03.00'" "$expected_1"
ItEchos "Date2Timestamp '2013-12-28_22.13.01'" "$expected_2"

ExitTests
