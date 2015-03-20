#!/bin/sh
# This file is licensed under the BSD-3-Clause license.
# See the AUTHORS and LICENSE files for more information.

. ../spec_helper.sh
. ../../share/zfsnap/core.sh

# These pools exist and should be accepted.
POOLS='zpool'
ItReturns "PoolExists 'zpool'"                                  0   # single prefix

POOLS='zpool data'
ItReturns "PoolExists 'zpool'"                                  0   # first pool w/ two pools defined
ItReturns "PoolExists 'data'"                                   0   # second pool w/ two pools defined

POOLS='zpool data random repos'
ItReturns "PoolExists 'repos'"                                  0   # last pool w/ many pools defined
ItReturns "PoolExists 'data'"                                   0   # middle pool w/ many pools defined
ItReturns "PoolExists 'zpool'"                                  0   # first pool w/ many pools defined

# These pools do not exist and should be rejected.
POOLS='zpool data repos'
ItReturns "PoolExists"                                          1 # empty is not a valid pool
ItReturns "PoolExists fake_zpool"                               1 # non-existant pool

ExitTests
