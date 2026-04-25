#!/bin/sh

. ../spec_helper.sh
. ../../zfSnap.sh

# No scrub/resilver skip enabled → should return 0
scrub_skip="false"
resilver_skip="false"
ItReturns "SkipPool tank/fs" 0

# Scrub skip enabled, pool not scrubbing → should return 0
scrub_skip="true"
scrub_pools="otherpool"
resilver_skip="false"
ItReturns "SkipPool tank/fs" 0

# Scrub skip enabled, pool IS scrubbing → should return 1
scrub_skip="true"
scrub_pools="tank"
resilver_skip="false"
verbose="false"
ItReturns "SkipPool tank/fs" 1

# Resilver skip enabled, pool IS resilvering → should return 1
scrub_skip="false"
resilver_skip="true"
resilver_pools="tank"
verbose="false"
ItReturns "SkipPool tank/fs" 1

# Both skip enabled, pool in neither → should return 0
scrub_skip="true"
scrub_pools="otherpool"
resilver_skip="true"
resilver_pools="anotherpool"
ItReturns "SkipPool tank/fs" 0

ExitTests
