#!/bin/sh
# This file is licensed under the BSD-3-Clause license.
# See the AUTHORS and LICENSE files for more information.

. ../spec_helper.sh
. ../../share/zfsnap/core.sh

# These include a date pattern, and should be trimmed accordingly
ItEchos "TrimToPrefix '2011-04-05_02.06.00--1y'"               ""          # w/o prefix
ItEchos "TrimToPrefix 'hourly-2011-04-05_02.06.00--1y'"        "hourly-"   # prefix
ItEchos "TrimToPrefix 'daily--2011-04-05_02.06.00--1y'"        "daily--"   # prefix using TTL delim

# These don't contain a date pattern, and should return an empty string
ItEchos "TrimToPrefix ''"                                      ""          # empty
ItEchos "TrimToPrefix 'zpool/child/grandchild'"                ""          # pool/fs
ItEchos "TrimToPrefix 'zpool@yesterday'"                       ""          # full snapshot, w/ no prefix or date
ItEchos "TrimToPrefix 'zpool@weekly--1y3w'"                    ""          # full snapshot, w/ supposed "prefix" and TTL, but no date

ExitTests
