#!/bin/sh

# This file is licensed under the BSD-3-Clause license.
# See the AUTHORS and LICENSE files for more information.

VM_BSD='freebsd10'
VM_LINUX='wheezy fedora'
VM_OSX='osx'
VM_SUNOS='omnios solaris11'
VM_ALL="$VM_BSD $VM_LINUX $VM_OSX $VM_SUNOS"
VMS_TO_TEST=''
FAILED_VMS=''
VERSION='0.1'

Help() {
    cat << EOF
${0##*/} v${VERSION}

Syntax:
${0##*/} [ options ]
Copy zfsnap to vagrant VMs and run test suite

OPTIONS:
  --all             = Run tests on all vagrant VMs
  --all-bsd         = Run tests on all BSD vagrant VMs
  --all-linux       = Run tests on all Linux vagrant VMs
  --all-osx         = Run tests on all OS X vagrant VMs
  --all-sunos       = Run tests on all SunOS vagrant VMs
  -h, --help        = Print this help and exit
  -V, --version     = Print the version number and exit

EOF
exit 0
}

# make sure at least one option is provided
[ -z "$1" ] && Help

while [ "$1" ]; do
    case "$1" in
        '--all') VMS_TO_TEST="${VMS_TO_TEST:+$VMS_TO_TEST }${VM_ALL}";;
        '--all-bsd') VMS_TO_TEST="${VMS_TO_TEST:+$VMS_TO_TEST }${VM_BSD}";;
        '--all-linux') VMS_TO_TEST="${VMS_TO_TEST:+$VMS_TO_TEST }${VM_LINUX}";;
        '--all-osx') VMS_TO_TEST="${VMS_TO_TEST:+$VMS_TO_TEST }${VM_OSX}";;
        '--all-sunos') VMS_TO_TEST="${VMS_TO_TEST:+$VMS_TO_TEST }${VM_SUNOS}";;
        '-h'|'--help'|'') Help;;
        '-V'|'--version') printf '%s v%s\n' "${0##*/}" "${VERSION}"; exit 0;;
        *) printf '%s is not a valid option.\n' "$1"; exit 1;;
    esac

    shift
done

for VM in $VMS_TO_TEST; do
    vagrant up "$VM"
    [ "$?" -ne 0 ] && FAILED_VMS="${FAILED_VMS:+$FAILED_VMS }$VM"
    vagrant halt "$VM"
done

if [ "$FAILED_VMS" = '' ]; then
    printf "\n\033[1;32m%s\033[0m\n" "All VMs passed the test suite."
else
    printf "\n\033[1;31m%s %s\033[0m\n" "The following VM(s) had failed tests:" "$FAILED_VMS" >&2
    exit 1
fi
