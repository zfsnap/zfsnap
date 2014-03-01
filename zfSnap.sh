#!/bin/sh

# "THE BEER-WARE LICENSE":
# <graudeejs@yandex.com> wrote this file. As long as you retain this notice you
# can do whatever you want with this stuff. If we meet some day, and you think
# this stuff is worth it, you can buy me a beer in return. Aldis Berjoza

# wiki:             https://github.com/graudeejs/zfSnap/wiki
# repository:       https://github.com/graudeejs/zfSnap
# bug tracking:     https://github.com/graudeejs/zfSnap/issues

# import zfSnap's library
zfSnap_lib_dir=~/git/zfSnap/
. "$zfSnap_lib_dir"/zfSnap_lib.sh

## FUNCTIONS

Help() {
    cat << EOF
${0##*/} v${VERSION}

Syntax:
${0##*/} [ options ] <command> [ options ] zpool/filesystem ...

COMMANDS:
  destroy           = destroy snapshots
  snapshot          = create snapshots

OPTIONS:
  -h                = Print this help and exit.

MORE HELP:
  All commands accept the -h option. Use that for more information.
  Example: ${0##*/} snapshot -h

LINKS:
  wiki:             https://github.com/graudeejs/zfSnap/wiki
  repository:       https://github.com/graudeejs/zfSnap
  bug tracking:     https://github.com/graudeejs/zfSnap/issues

EOF
    Exit 0
}

# MAIN

# get script command
case "$1" in
    'destroy')
        shift; . ./zfSnap-destroy.sh;;
    'snapshot')
        shift; . ./zfSnap-snapshot.sh;;
    '-h'|'')
        Help;;
    *)
        Fatal "'$1' is not a valid ${0##*/} command.";;
esac

IsTrue $count_failures && Exit $failures
Exit 0
# vim: set ts=4 sw=4 expandtab:
