#!/bin/sh
# This file is licensed under the BSD-3-Clause license.
# See the AUTHORS and LICENSE files for more information.

. ../spec_helper.sh

zfsnap="../../sbin/zfsnap.sh"

# These are invalid argument scenarios and should be rejected
# All are preceeded with -n for safety
ItReturns "$zfsnap snapshot -n -a 2> /dev/null"                               1 # -a requires an argument
ItReturns "$zfsnap snapshot -n -F 2> /dev/null"                               1 # -F requires an argument
ItReturns "$zfsnap snapshot -g 2> /dev/null"                                  1 # -g is not a valid option

# These are valid scenarios and should be accepted
ItReturns "$zfsnap snapshot -n -v -v 2> /dev/null"                            0 # option twice is ok, though sometimes pointless
#ItReturns "$zfsnap snapshot -n -r fake_zpool0 fake_zpool1 2> /dev/null"       0 # more than one zpool
#ItReturns "$zfsnap snapshot -n fake_zpool0 fake_zpoool1 -r fake_zpool2 2> /dev/null"  0 # pool option declared between zpools

ExitTests
