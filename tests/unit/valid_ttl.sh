#!/bin/sh

. ../spec_helper.sh
. ../../share/zfSnap/core.sh

# These are invalid TTLs and should be rejected
ItReturns "ValidTTL 1d5y"           1   # incorrect order
ItReturns "ValidTTL 1M5m"           1   # incorrect order in case sensitive scenario
ItReturns "ValidTTL 1D"             1   # wrong case for otherwise valid modifier
ItReturns "ValidTTL 1dd"            1   # double modifier
ItReturns "ValidTTL 1d5d"           1   # same modifier defined twice
ItReturns "ValidTTL 9y4w2d8w"       1   # same modifier defined twice, but seperated by another modifier
ItReturns "ValidTTL 1ms"            1   # valid modifiers, in order, not seperated by digit
ItReturns "ValidTTL 1y5"            1   # modifiers used, but last digit has missing modifier
ItReturns "ValidTTL 3600"           1   # (implied) seconds only is not a TTL
ItReturns "ValidTTL"                1   # empty is not a TTL

# These are valid TTLs and should be accepted
ItReturns "ValidTTL 1y2m3w4d5h6M7s" 0   # test all valid modifiers in order
ItReturns "ValidTTL 7y5h"           0   # skip a few modifiers
ItReturns "ValidTTL 10y24d5s"       0   # use double digits with modifiers
ItReturns "ValidTTL 4000d"          0   # use a very large number
ItReturns "ValidTTL 1m"             0   # test the default TTL

ExitTests
