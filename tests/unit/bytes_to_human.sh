#!/bin/sh
# This file is licensed under the BSD-3-Clause license.
# See the AUTHORS and LICENSE files for more information.

. ../spec_helper.sh
. ../../share/zfsnap/core.sh

# Easy, round conversions
ItsRetvalIs "BytesToHuman '100'"                  "100"   0  # 100 Bytes
ItsRetvalIs "BytesToHuman '9216'"                 "9K"    0  # 1 Kibibyte
ItsRetvalIs "BytesToHuman '5242880'"              "5M"    0  # 1 Mebibyte
ItsRetvalIs "BytesToHuman '3221225472'"           "3G"    0  # 1 Gibibyte
ItsRetvalIs "BytesToHuman '1099511627776'"        "1T"    0  # 1 Tebibyte
ItsRetvalIs "BytesToHuman '1125899906842624'"     "1P"    0  # 1 Pebibyte
ItsRetvalIs "BytesToHuman '1152921504606846976'"  "1E"    0  # 1 Exbibyte

# decimals
ItsRetvalIs "BytesToHuman '7864320'"              "7.5M"  0  # exactly 7.5
ItsRetvalIs "BytesToHuman '7864420'"              "7.5M"  0  # slightly off 7.5
ItsRetvalIs "BytesToHuman '3425236418'"           "3.1G"  0  # ~3.19
ItsRetvalIs "BytesToHuman '1046'"                 "1K"    0  # 1.0 should have no decimal

# Invalid TTL
ItsRetvalIs "BytesToHuman 'lmnop'"                ""      1  # Shouldn't happen, but worth testing.

ExitTests
