#!/bin/sh

. ../spec_helper.sh
. ../../share/zfSnap/core.sh

ItEchos "Seconds2TTL 0"         ""
ItEchos "Seconds2TTL 1"         "1s"
ItEchos "Seconds2TTL 59"        "59s"
ItEchos "Seconds2TTL 60"        "1M"
ItEchos "Seconds2TTL 3600"      "1h"
ItEchos "Seconds2TTL 86400"     "1d"
ItEchos "Seconds2TTL 2592000"   "1m"
ItEchos "Seconds2TTL 31104000"  "12m"
ItEchos "Seconds2TTL 31536000"  "1y"
ItEchos "Seconds2TTL 71211967"  "2y3m4d5h6M7s"

ExitTests
