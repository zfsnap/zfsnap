#!/bin/sh

. ../spec_helper.sh

zfSnap="../../zfSnap.sh"

# These are invalid argument scenarios and should be rejected
# All are preceeded with -n for safety
ItReturns "$zfSnap -n -a"                               1 # -a requires an argument
ItReturns "$zfSnap -n -F"                               1 # -F requires an argument
ItReturns "$zfSnap -n -a 1d -r fake_zpool -v"           1 # generic option after a pool option

# These are valid scenarios and should be accepted
ItReturns "$zfSnap -n -v -v"                            0 # generic option twice is ok, though pointless
ItReturns "$zfSnap -n -r fake_zpool0 fake_zpool1"       0 # more than one zpool
ItReturns "$zfSnap -n fake_zpool0 fake_zpoool1 -r fake_zpool2"  0 # pool option declared between zpools

ExitTests
