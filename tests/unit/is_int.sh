#!/bin/sh
# This file is licensed under the BSD-3-Clause license.
# See the AUTHORS and LICENSE files for more information.

. ../spec_helper.sh
. ../../share/zfsnap/core.sh

# Integers
ItReturns "IsInt '2012'"                      0   # typical year
ItReturns "IsInt '8'"                         0   # typical ttl
ItReturns "IsInt '02'"                        0   # typical day/month (leading zero)
ItReturns "IsInt '832450932181236543'"        0   # huge number
ItReturns "IsInt '0'"                         0   # zero

# Not integers.
ItReturns "IsInt 'lmnop'"                     1   # string
ItReturns "IsInt '2 965'"                     1   # ints with a space
ItReturns "IsInt '3.14'"                      1   # float isn't an int
ItReturns "IsInt '3,123'"                     1   # separators aren't cool
ItReturns "IsInt ''"                          1   # empty string
ItReturns "IsInt ' '"                         1   # space

ExitTests
