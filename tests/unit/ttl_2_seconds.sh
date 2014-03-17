#!/bin/sh
# This file is licensed under the BSD-3-Clause license.
# See the AUTHORS and LICENSE files for more information.

. ../spec_helper.sh
. ../../share/zfsnap/core.sh

ItRetvals "TTL2Seconds ''"              "0"
ItRetvals "TTL2Seconds '1s'"            "1"
ItRetvals "TTL2Seconds '59s'"           "59"
ItRetvals "TTL2Seconds '1M'"            "60"
ItRetvals "TTL2Seconds '1h'"            "3600"
ItRetvals "TTL2Seconds '1d'"            "86400"
ItRetvals "TTL2Seconds '1m'"            "2592000"
ItRetvals "TTL2Seconds '12m'"           "31104000"
ItRetvals "TTL2Seconds '1y'"            "31536000"
ItRetvals "TTL2Seconds '2y3m4d5h6M7s'"  "71211967"

ExitTests
