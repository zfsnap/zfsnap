#!/bin/sh
# This file is licensed under the BSD-3-Clause license.
# See the AUTHORS and LICENSE files for more information.

. ../spec_helper.sh
. ../../share/zfsnap/core.sh

# easy, round conversions
ItsRetvalIs "BytesToHuman '100'"                   "100"   0  # 100 Bytes
ItsRetvalIs "BytesToHuman '9216'"                  "9K"    0  # 1 Kibibyte
ItsRetvalIs "BytesToHuman '5242880'"               "5M"    0  # 1 Mebibyte
ItsRetvalIs "BytesToHuman '3221225472'"            "3G"    0  # 1 Gibibyte
ItsRetvalIs "BytesToHuman '1099511627776'"         "1T"    0  # 1 Tebibyte
ItsRetvalIs "BytesToHuman '1125899906842624'"      "1P"    0  # 1 Pebibyte
ItsRetvalIs "BytesToHuman '1152921504606846976'"   "1E"    0  # 1 Exbibyte

# not as easy, not round conversions
ItsRetvalIs "BytesToHuman '56145'"                 "54.8K" 0

# decimals
ItsRetvalIs "BytesToHuman '7864320'"               "7.5M"  0  # exactly 7.5
ItsRetvalIs "BytesToHuman '7864420'"               "7.5M"  0  # slightly above 7.5
ItsRetvalIs "BytesToHuman '3425236418'"            "3.1G"  0  # ~3.19
ItsRetvalIs "BytesToHuman '76624965339709'"        "69.6T" 0  # ~69.69
ItsRetvalIs "BytesToHuman '1046'"                  "1K"    0  # 1.0 should have no decimal
ItsRetvalIs "BytesToHuman '10580140'"              "10M"   0  # ~10.09

# multiple digits
ItsRetvalIs "BytesToHuman '103857600'"             "99.1M" 0  #
ItsRetvalIs "BytesToHuman '943718400'"             "900M"  0  # 900 Mebibytes
ItsRetvalIs "BytesToHuman '1020054732'"            "972M"  0  # 972 Mebibytes
ItsRetvalIs "BytesToHuman '1073741823'"            "1G"    0  # just under, but it's ok
ItsRetvalIs "BytesToHuman '1073741824'"            "1G"    0  # exactly 1 GB

# just above and below a tuplet
ItsRetvalIs "BytesToHuman '999'"                   "999"   0  # 3 digits
ItsRetvalIs "BytesToHuman '1000'"                  "1000"  0  # 4 digits
ItsRetvalIs "BytesToHuman '999999'"                "976K"  0  # 6 digits
ItsRetvalIs "BytesToHuman '1000000'"               "976K"  0  # 7 digits
ItsRetvalIs "BytesToHuman '999999999'"             "954M"  0  # 9 digits; true answer is 953M, but I'm ok with some jitter
ItsRetvalIs "BytesToHuman '1000000000'"            "953M"  0  # 10 digits
ItsRetvalIs "BytesToHuman '999999999999'"          "931G"  0  # 12 digits
ItsRetvalIs "BytesToHuman '1000000000000'"         "931G"  0  # 13 digits
ItsRetvalIs "BytesToHuman '999999999999999'"       "909T"  0  # 15 digits
ItsRetvalIs "BytesToHuman '1000000000000000'"      "909T"  0  # 16 digits
ItsRetvalIs "BytesToHuman '999999999999999999'"    "888P"  0  # 18 digits
ItsRetvalIs "BytesToHuman '1000000000000000000'"   "888P"  0  # 19 digits
ItsRetvalIs "BytesToHuman '999999999999999999999'" "868E"  0  # 21 digits; true answer is 867E, but I'm ok with some jitter

# valley-of-awkwardness tests (between 1000 and 1024)
ItsRetvalIs "BytesToHuman '1011'"                  "1011"  0  # Bytes
ItsRetvalIs "BytesToHuman '1025024'"               "1001K" 0  # KiB
ItsRetvalIs "BytesToHuman '1071644672'"            "1022M" 0  # MiB
ItsRetvalIs "BytesToHuman '1073741824000'"         "1000G" 0  # GiB
ItsRetvalIs "BytesToHuman '1120402348703744'"      "1019T" 0  # TiB
ItsRetvalIs "BytesToHuman '1132655306283679744'"   "1006P" 0  # PiB

# invalid argument
ItsRetvalIs "BytesToHuman 'lmnop'"                 ""      1  # shouldn't happen, but worth testing

ExitTests
