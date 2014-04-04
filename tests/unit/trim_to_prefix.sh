#!/bin/sh
# This file is licensed under the BSD-3-Clause license.
# See the AUTHORS and LICENSE files for more information.

. ../spec_helper.sh
. ../../share/zfsnap/core.sh

# These include a date pattern, and should be trimmed accordingly
PREFIXES=''
ItRetvals "TrimToPrefix '2011-04-05_02.06.00--1y'"               ""         0 # w/o prefix

PREFIXES='daily-- hourly-'
ItRetvals "TrimToPrefix 'hourly-2011-04-05_02.06.00--1y'"        "hourly-"  0 # prefix
ItRetvals "TrimToPrefix 'daily--2011-04-05_02.06.00--1y'"        "daily--"  0 # prefix using TTL delim

# These don't contain a date pattern, and should return an empty string
PREFIXES=''
ItRetvals "TrimToPrefix 'hourly-2011-04-05_02.06.00--1y'"        ""         1 # invalid prefix

PREFIXES='daily-- hourly-'
ItRetvals "TrimToPrefix ''"                                      ""         1 # empty
ItRetvals "TrimToPrefix 'weekly-2011-04-05_02.06.00--1y'"        ""         1 # invalid prefix
ItRetvals "TrimToPrefix '2011-04-05_02.06.00--1y'"               ""         1 # invalid (empty) prefix
ItRetvals "TrimToPrefix 'zpool/child/grandchild'"                ""         1 # pool/fs
ItRetvals "TrimToPrefix 'zpool@yesterday'"                       ""         1 # full snapshot, w/ no prefix or date
ItRetvals "TrimToPrefix 'zpool@weekly--1y3w'"                    ""         1 # full snapshot, w/ supposed "prefix" and TTL, but no date

ExitTests
