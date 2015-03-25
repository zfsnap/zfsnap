#!/bin/sh

# This file is licensed under the BSD-3-Clause license.
# See the AUTHORS and LICENSE files for more information.

# See the PORTABILITY file for more information about why some Bourne shells
# are tested and not others

SHELLS_GOOD='ash bash dash pdksh posh zsh sh'
SHELLS_BAD='mksh'
SHELLS_HOPELESS='ksh93' # not used, here to document
SHELLS_ALL="$SHELLS_GOOD $SHELLS_BAD"
SHELLS_TO_TEST=''
FAILED_SHELLS=''
VERSION='0.1'

Help() {
    cat << EOF
${0##*/} v${VERSION}

Syntax:
${0##*/} [ options ]
run test suite under various shells

OPTIONS:
  --all             = Run tests on all shells
  --all-good        = run tests on all known good Bourne shells
  --all-bad         = run tests on all known bad Bourne shells
  -h, --help        = Print this help and exit
  -V, --version     = Print the version number and exit

EOF
exit 0
}

# make sure at least one option is provided
[ -z "$1" ] && Help

while [ "$1" ]; do
    case "$1" in
        '--all') SHELLS_TO_TEST="${SHELLS_TO_TEST:+SHELLS_TO_TEST }${SHELLS_ALL}";;
        '--all-bad') SHELLS_TO_TEST="${SHELLS_TO_TEST:+SHELLS_TO_TEST }${SHELLS_BAD}";;
        '--all-good') SHELLS_TO_TEST="${SHELLS_TO_TEST:+SHELLS_TO_TEST }${SHELLS_GOOD}";;
        '-h'|'--help'|'') Help;;
        '-V'|'--version') printf '%s v%s\n' "${0##*/}" "${VERSION}"; exit 0;;
        *) printf '%s is not a valid option.\n' "$1"; exit 1;;
    esac

    shift
done

cd ../

for BANG in $SHELLS_TO_TEST; do
    SHE='#!/bin/'

    # change the shebangs
    find ../ -type d \( -name tools -o -name vagrant \) -prune -o -type f \
        -exec ../tools/mod_shebang.sh -s "${SHE}${BANG}" {} \;

    ./run.sh
    [ "$?" -ne 0 ] && FAILED_SHELLS="${FAILED_SHELLS:+$FAILED_SHELLS }$BANG"
    printf "%s\n\n" "$BANG"
done

cd vagrant/

if [ "$FAILED_SHELLS" = '' ]; then
    printf "\n\033[1;32m%s\033[0m\n" "All shells passed the test suite."
else
    printf "\n\033[1;31m%s %s\033[0m\n" "The following shell(s) had failed tests:" "$FAILED_SHELLS" >&2
    exit 1
fi
