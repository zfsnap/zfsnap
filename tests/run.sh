#!/bin/sh
# This file is licensed under the BSD-3-Clause license.
# See the AUTHORS and LICENSE files for more information.

exit_with_error=0

for i in unit integration; do
    cd "$i"
    for t in `ls`; do
        sh "$t"
        [ $? -ne 0 ] && exit_with_error=1
    done
    cd ..
done

if [ $exit_with_error -eq 0 ]; then
    printf "\n\033[1;32m%s\033[0m\n" "All tests passed."
else
    printf "\n\033[1;31m%s\033[0m\n" "Some tests failed." >&2
    exit 1
fi
