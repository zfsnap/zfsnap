#!/bin/sh
# This file is licensed under the BSD-3-Clause license.
# See the AUTHORS and LICENSE files for more information.

. ../spec_helper.sh

zfsnap='../../sbin/zfsnap.sh'
zfs=`which zfs`

DATASET="$TEST_POOL/$TEST_DATASET"

CREATE_DATE="2020-01-01_10.00.00"
DELETE_DATE="2020-03-01_10.00.00"

echo ""
echo "Destroy without any options"
CreateSnap "$DATASET@$CREATE_DATE--1m"
CreateSnap "$DATASET@$CREATE_DATE--3m"
for subds in $TEST_SUBDATASETS
do
	CreateSnap "$DATASET/$subds@$CREATE_DATE--1m"
	CreateSnap "$DATASET/$subds@$CREATE_DATE--3m"
done
ItReturns "CURRENT_DATE=$DELETE_DATE $zfsnap destroy $DATASET 2> /dev/null" 0
VerifySnapNotExists "$DATASET@$CREATE_DATE--1m"
VerifySnapExists "$DATASET@$CREATE_DATE--3m"
DestroySnap "$DATASET@$CREATE_DATE--3m"
for subds in $TEST_SUBDATASETS
do
	DestroySnap "$DATASET/$subds@$CREATE_DATE--1m"
	DestroySnap "$DATASET/$subds@$CREATE_DATE--3m"
done

echo ""
echo "Destroy all snapshots (-D)"
CreateSnap "$DATASET@$CREATE_DATE--1m"
CreateSnap "$DATASET@$CREATE_DATE--3m"
for subds in $TEST_SUBDATASETS
do
	CreateSnap "$DATASET/$subds@$CREATE_DATE--1m"
	CreateSnap "$DATASET/$subds@$CREATE_DATE--3m"
done
ItReturns "CURRENT_DATE=$DELETE_DATE $zfsnap destroy -D $DATASET 2> /dev/null" 0
VerifySnapNotExists "$DATASET@$CREATE_DATE--1m"
VerifySnapNotExists "$DATASET@$CREATE_DATE--3m"
for subds in $TEST_SUBDATASETS
do
	DestroySnap "$DATASET/$subds@$CREATE_DATE--1m"
	DestroySnap "$DATASET/$subds@$CREATE_DATE--3m"
done

echo ""
echo "Recursive destroy (-r)"
CreateSnap "$DATASET@$CREATE_DATE--1m"
CreateSnap "$DATASET@$CREATE_DATE--3m"
for subds in $TEST_SUBDATASETS
do
	CreateSnap "$DATASET/$subds@$CREATE_DATE--1m"
	CreateSnap "$DATASET/$subds@$CREATE_DATE--3m"
done
ItReturns "CURRENT_DATE=$DELETE_DATE $zfsnap destroy -r $DATASET 2> /dev/null" 0
VerifySnapNotExists "$DATASET@$CREATE_DATE--1m"
VerifySnapExists "$DATASET@$CREATE_DATE--3m"
DestroySnap "$DATASET@$CREATE_DATE--3m"
for subds in $TEST_SUBDATASETS
do
	VerifySnapNotExists "$DATASET/$subds@$CREATE_DATE--1m"
	DestroySnap "$DATASET/$subds@$CREATE_DATE--3m"
done

echo ""
echo "Recursive destroy all snapshots (-r -D)"
CreateSnap "$DATASET@$CREATE_DATE--1m"
CreateSnap "$DATASET@$CREATE_DATE--3m"
for subds in $TEST_SUBDATASETS
do
	CreateSnap "$DATASET/$subds@$CREATE_DATE--1m"
	CreateSnap "$DATASET/$subds@$CREATE_DATE--3m"
done
ItReturns "CURRENT_DATE=$DELETE_DATE $zfsnap destroy -r -D $DATASET 2> /dev/null" 0
VerifySnapNotExists "$DATASET@$CREATE_DATE--1m"
VerifySnapNotExists "$DATASET@$CREATE_DATE--3m"
for subds in $TEST_SUBDATASETS
do
	VerifySnapNotExists "$DATASET/$subds@$CREATE_DATE--1m"
	VerifySnapNotExists "$DATASET/$subds@$CREATE_DATE--3m"
done

echo ""
echo "Prefixed destroy (-p)"
CreateSnap "$DATASET@zs$CREATE_DATE--1m"
CreateSnap "$DATASET@zs$CREATE_DATE--3m"
for subds in $TEST_SUBDATASETS
do
	CreateSnap "$DATASET/$subds@zs$CREATE_DATE--1m"
	CreateSnap "$DATASET/$subds@zs$CREATE_DATE--3m"
done
ItReturns "CURRENT_DATE=$DELETE_DATE $zfsnap destroy -p zs $DATASET 2> /dev/null" 0
VerifySnapNotExists "$DATASET@zs$CREATE_DATE--1m"
VerifySnapExists "$DATASET@zs$CREATE_DATE--3m"
DestroySnap "$DATASET@zs$CREATE_DATE--3m"
for subds in $TEST_SUBDATASETS
do
	DestroySnap "$DATASET/$subds@zs$CREATE_DATE--1m"
	DestroySnap "$DATASET/$subds@zs$CREATE_DATE--3m"
done

ExitTests
