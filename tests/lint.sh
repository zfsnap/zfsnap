#!/bin/sh

export DIRS_WITH_SCRIPTS="periodic sbin share/zfsnap share/zfsnap/commands tools"

ERRS=0

for _dir in $DIRS_WITH_SCRIPTS
do
    for _f in $_dir/*.sh
    do
        sh -n "$_f"
        echo "shellcheck $_f"
        shellcheck -x -s sh -e SC1090,SC1091,SC2009,SC2015,SC2034,SC2039,SC2086,SC2153,SC2016,SC1004,SC2119 $_f || ERRS=$((ERRS + 1))
    done
done

if [ $ERRS -eq 0 ]; then
    exit 0
fi

echo "Lint errors encountered"
exit 1
