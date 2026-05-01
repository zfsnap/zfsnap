#!/bin/sh
# This file is licensed under the BSD-3-Clause license.
# See the AUTHORS and LICENSE files for more information.

. ../spec_helper.sh

zfsnap='../../sbin/zfsnap.sh'
zfs=`which zfs`

DATASET="$TEST_POOL/$TEST_DATASET"

TEST_DATE="2020-01-01_10.00.00"

echo ""
echo "Snapshot without any options"
VerifySnapNotExists "$DATASET@$TEST_DATE--1m"
ItReturns "CURRENT_DATE=$TEST_DATE $zfsnap snapshot $DATASET 2> /dev/null" 0
for subds in $TEST_SUBDATASETS
do
	VerifySnapNotExists "$DATASET/$subds@$TEST_DATE--1m"
done
DestroySnap "$DATASET@$TEST_DATE--1m"

echo ""
echo "Prefixed snapshot (-p)"
VerifySnapNotExists "$DATASET@zs-$TEST_DATE--1m"
ItReturns "CURRENT_DATE=$TEST_DATE $zfsnap snapshot -p zs $DATASET 2> /dev/null" 0
for subds in $TEST_SUBDATASETS
do
	VerifySnapNotExists "$DATASET/$subds@zs-$TEST_DATE--1m"
done
DestroySnap "$DATASET@zs-$TEST_DATE--1m"

echo ""
echo "Snapshot with 1y TTL (-a)"
VerifySnapNotExists "$DATASET@$TEST_DATE--1y"
ItReturns "CURRENT_DATE=$TEST_DATE $zfsnap snapshot -a 1y $DATASET 2> /dev/null" 0
for subds in $TEST_SUBDATASETS
do
	VerifySnapNotExists "$DATASET/$subds@$TEST_DATE--1y"
done
DestroySnap "$DATASET@$TEST_DATE--1y"

TEST_DATE="2020-02-01_10.00.00"

echo ""
echo "Recursive snapshot (-r)"
VerifySnapNotExists "$DATASET@$TEST_DATE--1m"
for subds in $TEST_SUBDATASETS
do
	VerifySnapNotExists "$DATASET/$subds@$TEST_DATE--1m"
done
ItReturns "CURRENT_DATE=$TEST_DATE $zfsnap snapshot -r $DATASET 2> /dev/null" 0
for subds in $TEST_SUBDATASETS
do
	DestroySnap "$DATASET/$subds@$TEST_DATE--1m"
done
DestroySnap "$DATASET@$TEST_DATE--1m"

ExitTests
