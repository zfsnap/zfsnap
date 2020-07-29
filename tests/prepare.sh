#!/bin/sh
# This file is licensed under the BSD-3-Clause license.
# See the AUTHORS and LICENSE files for more information.

#
# Prepare ZFS environment for testing
#
. ./spec_helper.sh
zfs=`which zfs`

DATASET="$TEST_POOL/$TEST_DATASET"

set -x
if ! $zfs list -H $DATASET
then
	if ! zfs list -H $TEST_POOL
	then
		dd if=/dev/zero of=/tmp/tpool bs=1M count=256 || exit 1
		zpool create tpool /tmp/tpool || exit 1
		zpool list -v tpool || exit 1
	fi
	zfs create tpool/test || exit 1
	zfs list tpool/test || exit 1
fi
for subds in $TEST_SUBDATASETS
do
	if ! $zfs list -H $DATASET/$subds
	then
		zfs create $DATASET/$subds || exit 1
		zfs list $DATASET/$subds || exit 1
	fi
done
