#!/bin/sh
# This file is licensed under the BSD-3-Clause license.
# See the AUTHORS and LICENSE files for more information.

. ../spec_helper.sh
. ../../share/zfsnap/core.sh

# These include a date pattern, and should be trimmed accordingly
PREFIXES='daily-- hourly-'
ItRetvals "TrimToPrefix '2011-04-05_02.06.00--1y'"               ""          # w/o prefix
ItRetvals "TrimToPrefix 'hourly-2011-04-05_02.06.00--1y'"        "hourly-"   # prefix
ItRetvals "TrimToPrefix 'daily--2011-04-05_02.06.00--1y'"        "daily--"   # prefix using TTL delim

# These don't contain a date pattern, and should return an empty string
PREFIXES='daily-- hourly-'
ItRetvals "TrimToPrefix ''"                                      ""          # empty
ItRetvals "TrimToPrefix 'weekly-2011-04-05_02.06.00--1y'"        ""          # invalid prefix
ItRetvals "TrimToPrefix '2011-04-05_02.06.00--1y'"               ""          # invalid prefix
ItRetvals "TrimToPrefix 'zpool/child/grandchild'"                ""          # pool/fs
ItRetvals "TrimToPrefix 'zpool@yesterday'"                       ""          # full snapshot, w/ no prefix or date
ItRetvals "TrimToPrefix 'zpool@weekly--1y3w'"                    ""          # full snapshot, w/ supposed "prefix" and TTL, but no date

ExitTests
