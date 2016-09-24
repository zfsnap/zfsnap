#!/bin/sh

export DIRS_WITH_SCRIPTS="periodic sbin share/zfsnap share/zfsnap/commands tools"

pwd

for _dir in $DIRS_WITH_SCRIPTS
do
    for _f in $_dir/*.sh
    do
        sh -n "$_f"
        echo "shellcheck $_f"
        shellcheck -e SC2009,SC2086,SC2153,SC2016,SC1004,SC2119 "$_f"
    done
done
