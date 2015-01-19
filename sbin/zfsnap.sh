#!/bin/sh

# This file is licensed under the BSD-3-Clause license.
# See the AUTHORS and LICENSE files for more information.
#
# wiki:             https://github.com/zfsnap/zfsnap/wiki
# repository:       https://github.com/zfsnap/zfsnap
# bug tracking:     https://github.com/zfsnap/zfsnap/issues

# import zfsnap's library
ABSOLUTE_ZFSNAP=`readlink -f "$0"`
ABSOLUTE_ZFSNAP_DIR=`dirname "$ABSOLUTE_ZFSNAP"`
ZFSNAP_LIB_DIR="${ZFSNAP_LIB_DIR:-${ABSOLUTE_ZFSNAP_DIR%/*}/share/zfsnap}"
. "$ZFSNAP_LIB_DIR/core.sh"

## FUNCTIONS

Help() {
    cat << EOF
${0##*/} v${VERSION}

Syntax:
${0##*/} [ options ] | <command> [ options ] zpool/filesystem ...

COMMANDS:
`for C in $ZFSNAP_LIB_DIR/commands/*.sh; do [ -f "$C" ] && C_NAME="${C##*/}" && printf '  %s\n' "${C_NAME%.*}"; done`

OPTIONS:
  -h, --help        = Print this help and exit
  -V, --version     = Print the version number and exit

MORE HELP:
  All commands accept the -h option; use it for command-specific help.
  Example: ${0##*/} snapshot -h

LINKS:
  wiki:             https://github.com/zfsnap/zfsnap/wiki
  repository:       https://github.com/zfsnap/zfsnap
  bug tracking:     https://github.com/zfsnap/zfsnap/issues

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
        if [ -f "${ZFSNAP_LIB_DIR}/commands/${CMD}.sh" ]; then
            shift
            . "${ZFSNAP_LIB_DIR}/commands/${CMD}.sh"
        else
            Fatal "'$CMD' is not a valid ${0##*/} command."
        fi
        ;;
esac

Exit 0
# vim: set ts=4 sw=4 expandtab:
