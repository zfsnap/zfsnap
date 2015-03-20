#!/bin/sh
# This file is licensed under the BSD-3-Clause license.
# See the AUTHORS and LICENSE files for more information.

EXIT_WITH_ERROR=0

for i in unit integration; do
    cd "$i"
    for t in ./* ; do
        "./${t}"
        [ "$?" -ne 0 ] && EXIT_WITH_ERROR=1
    done
    cd ..
done

if [ "$EXIT_WITH_ERROR" -eq 0 ]; then
    printf "\n\033[1;32m%s\033[0m\n" "All tests passed."
else
    printf "\n\033[1;31m%s\033[0m\n" "Some tests failed." >&2
    exit 1
fi
