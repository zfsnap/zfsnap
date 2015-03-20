#!/bin/sh
# This file is licensed under the BSD-3-Clause license.
# See the AUTHORS and LICENSE files for more information.

. ../spec_helper.sh
. ../../share/zfsnap/core.sh

# These include a valid prefix, and should be trimmed accordingly
PREFIXES=''
ItReturns "ValidPrefix ''"                                       0   # "Nothing" is the prefix when none are defined

PREFIXES='hourly-'
ItReturns "ValidPrefix 'hourly-'"                                0   # single prefix

PREFIXES='hourly- weekly-'
ItReturns "ValidPrefix 'hourly-'"                                0   # first prefix w/ two prefixes defined
ItReturns "ValidPrefix 'weekly-'"                                0   # second prefix w/ two prefixes defined

PREFIXES='hourly- weekly- monthly-'
ItReturns "ValidPrefix 'hourly-'"                                0   # first prefix w/ three prefixes defined
ItReturns "ValidPrefix 'weekly-'"                                0   # middle prefix w/ three prefixes defined
ItReturns "ValidPrefix 'monthly-'"                               0   # last prefix w/ three prefixes defined

# These don't contain a valid prefix, and should return an empty string
PREFIXES=''
ItReturns "ValidPrefix 'teal-'"                                  1   # invalid w/o a prefix defined

PREFIXES='hourly-'
ItReturns "ValidPrefix ''"                                       1   # empty w/ one prefix defined
ItReturns "ValidPrefix 'orange-'"                                1   # invalid w/ one prefix defined

PREFIXES='hourly- weekly-'
ItReturns "ValidPrefix 'blue-'"                                  1   # invalid w/ two prefixes defined

PREFIXES='hourly- weekly- monthly-'
ItReturns "ValidPrefix ''"                                       1   # empty w/ three prefixes defined
ItReturns "ValidPrefix 'black-'"                                 1   # invalid w/ three prefixes defined

PREFIXES='hourly- weekly- monthly-'
ItReturns "ValidPrefix 'zpool/child'"                            1   # filesystem submitted

PREFIXES='hour'
ItReturns "ValidPrefix 'hourly'"                                 1   # defined prefix is substring of submitted prefix

ExitTests
