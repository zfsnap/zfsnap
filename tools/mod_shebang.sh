#!/bin/sh

# This file is licensed under the BSD-3-Clause license.
# See the AUTHORS and LICENSE files for more information.

NEW_SHEBANG=''
VERSION='0.2'

Help() {
    cat << EOF
${0##*/} v${VERSION}

Syntax:
${0##*/} [ options ] -s new_shebang file [...]
Replace the shebang line in files

OPTIONS:
  -h                = Print this help and exit
  -s                = the shebang to use. e.g. '#!/bin/ksh'
  -V                = Print the version number and exit

EXAMPLES:
  Single File:
  mod_shebang.sh -s '#!/bin/bash' wicked_script.sh

  All Files in Folder:
  mod_shebang.sh -s '#!/bin/ksh' folder/*.sh

  # All Files Recursively in Folder
  find folder/ -type f -exec mod_shebang.sh -s '#!/bin/zsh' {} \;

EOF
exit 0
}

# options
while getopts :hs: OPT; do
    case "$OPT" in
        h) Help;;
        s) NEW_SHEBANG=$OPTARG;;
        V) printf '%s v%s\n' "${0##*/}" "${VERSION}"; exit 0;;

        :) printf "Option -%s requires an argument.\n" "${OPTARG}"; exit 1;;
        \?)  printf "Invalid option: -%s.\n" "${OPTARG}"; exit 1;;
    esac
done

# make sure a new shebang was provided
[ -z "$NEW_SHEBANG" ] && printf "You must specify a new shebang with the -s option.\n" && exit 1

# discard all arguments processed thus far
shift $(($OPTIND - 1))

while [ "$1" ]; do
    ORIG_FILE=`cat "$1"`

    # skip file if first line isn't a shebang
    FIRST=`printf '%s' "$ORIG_FILE" | head -1`
    [ -z "$FIRST" ] || [ -n "${FIRST%%#!*}" ] && shift && continue

    # note, this doesn't strip off the newline, but that newline is intentionally used later
    SANS_SHEBANG="${ORIG_FILE#${FIRST}}"

    # overwrite file
    printf '%s%s' "$NEW_SHEBANG" "$SANS_SHEBANG" >| "$1"

    shift
done
