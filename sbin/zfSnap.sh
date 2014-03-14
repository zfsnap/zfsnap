#!/bin/sh

# "THE BEER-WARE LICENSE":
# <graudeejs@yandex.com> wrote this file. As long as you retain this notice you
# can do whatever you want with this stuff. If we meet some day, and you think
# this stuff is worth it, you can buy me a beer in return. Aldis Berjoza

# wiki:             https://github.com/graudeejs/zfSnap/wiki
# repository:       https://github.com/graudeejs/zfSnap
# bug tracking:     https://github.com/graudeejs/zfSnap/issues

# import zfSnap's library
ZFSNAP_LIB_DIR="${ZFSNAP_LIB_DIR:-`readlink -f $(dirname $(dirname $0))`/share/zfSnap}"
. "$ZFSNAP_LIB_DIR/core.sh"

## FUNCTIONS

Help() {
    cat << EOF
${0##*/} v${VERSION}

Syntax:
${0##*/} [ options ] | <command> [ options ] zpool/filesystem ...

COMMANDS:
`find $ZFSNAP_LIB_DIR/commands -type f | sed 's#\.sh$##; s#^.*/##; s#^#  #'`

OPTIONS:
  -h, --help        = Print this help and exit.
  -V, --version     = Print the version number and exit

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

case "$1" in
    '-h'|'--help'|'')
        Help;;
    '-V'|'--version')
        printf '%s v%s\n' "${0##*/}" "${VERSION}"; Exit 0;;
    *)
        CMD="$1"
        if [ -f "$ZFSNAP_LIB_DIR/commands/${CMD}.sh" ]; then
            shift
            . "$ZFSNAP_LIB_DIR/commands/${CMD}.sh"
        else
            Fatal "'$CMD' is not a valid ${0##*/} command."
        fi
        ;;
esac

Exit 0
# vim: set ts=4 sw=4 expandtab:
