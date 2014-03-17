#!/bin/sh
# This file is licensed under the BSD-3-Clause license.
# See the AUTHORS and LICENSE files for more information.

. ../spec_helper.sh
. ../../share/zfsnap/core.sh

ItRetvals "Seconds2TTL 0"         ""
ItRetvals "Seconds2TTL 1"         "1s"
ItRetvals "Seconds2TTL 59"        "59s"
ItRetvals "Seconds2TTL 60"        "1M"
ItRetvals "Seconds2TTL 3600"      "1h"
ItRetvals "Seconds2TTL 86400"     "1d"
ItRetvals "Seconds2TTL 2592000"   "1m"
ItRetvals "Seconds2TTL 31104000"  "12m"
ItRetvals "Seconds2TTL 31536000"  "1y"
ItRetvals "Seconds2TTL 71211967"  "2y3m4d5h6M7s"

ExitTests
