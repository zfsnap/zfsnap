#!/bin/sh
# This file is licensed under the BSD-3-Clause license.
# See the AUTHORS and LICENSE files for more information.

. ../spec_helper.sh
. ../../share/zfsnap/core.sh

ItRetvals "Seconds2TTL 0"         ""              0
ItRetvals "Seconds2TTL 1"         "1s"            0
ItRetvals "Seconds2TTL 59"        "59s"           0
ItRetvals "Seconds2TTL 60"        "1M"            0
ItRetvals "Seconds2TTL 3600"      "1h"            0
ItRetvals "Seconds2TTL 86400"     "1d"            0
ItRetvals "Seconds2TTL 2592000"   "1m"            0
ItRetvals "Seconds2TTL 31104000"  "12m"           0
ItRetvals "Seconds2TTL 31536000"  "1y"            0
ItRetvals "Seconds2TTL 71211967"  "2y3m4d5h6M7s"  0

ExitTests
