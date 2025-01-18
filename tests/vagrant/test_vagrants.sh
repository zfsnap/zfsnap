#!/bin/sh

# This file is licensed under the BSD-3-Clause license.
# See the AUTHORS and LICENSE files for more information.

VM_BSD='freebsd10 freebsd11 freebsd12 freebsd13 freebsd14'
VM_DEBIAN='wheezy jessie stretch buster bullseye bookworm'
VM_UBUNTU='xenial bionic focal jammy noble'
VM_FEDORA20='fedora21 fedora22 fedora23 fedora24 fedora25 fedora26 fedora27 fedora28 fedora29'
VM_FEDORA30='fedora30 fedora31 fedora32 fedora33 fedora34 fedora35 fedora36 fedora37 fedora38'
VM_FEDORA40='fedora40 fedora41 fedora42 fedora43'
VM_FEDORA="$VM_FEDORA20 $VM_FEDORA30 $VM_FEDORA40"
VM_LINUX="$VM_DEBIAN $VM_UBUNTU $VM_FEDORA"
VM_OSX='osx1010 osx1011 osx1012 osx1013 osx1014 osx1015'
VM_OMNIOS='omnios12 omnios14 omnios16 omnios18 omnios20'
VM_SOLARIS10='solaris1006 solaris1006 solaris1007 solaris1008 solaris1009 solaris1010 solaris1011'
VM_SOLARIS11='solaris1100 solaris1101 solaris1102 solaris1103 solaris1104'
VM_SOLARIS="$VM_SOLARIS10 $VM_SOLARIS11"
VM_SUNOS="$VM_OMNIOS $VM_SOLARIS"
VM_ALL="$VM_BSD $VM_LINUX $VM_OSX $VM_SUNOS"
VMS_TO_TEST=''
FAILED_VMS=''
VERSION='0.2.0'

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
  --test            = Run tests on a specific vagrant VM
  --test-cleanup    = Cleanup all vagrant VMs
  --get-boxes       = Download vagrant VM images
  -h, --help        = Print this help and exit
  -V, --version     = Print the version number and exit

EOF
exit 0
}

# make sure at least one option is provided
[ -z "$1" ] && Help

run_tests() {
    VMS_TO_TEST="$@"
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
}

cleanup_vms() {
    VMS_TO_CLEANUP="$@"
    for VM in $VMS_TO_CLEANUP; do
        vagrant destroy -f "$VM"
    done
}

get_boxes() {
    BOXES=$(cat Vagrantfile | grep vm.box | awk -F'=' '{print $2}'| sed 's/[[:space:]]//g' | sed 's/"//g')
    for BOX in $BOXES; do
        vagrant box add "${BOX}" --provider virtualbox
    done
}

# parse command line
while [ "$1" ]; do
    case "$1" in
        '--all') VMS_TO_TEST="${VMS_TO_TEST:+$VMS_TO_TEST }${VM_ALL}";;
        '--all-bsd') VMS_TO_TEST="${VMS_TO_TEST:+$VMS_TO_TEST }${VM_BSD}";;
        '--all-linux') VMS_TO_TEST="${VMS_TO_TEST:+$VMS_TO_TEST }${VM_LINUX}";;
        '--all-osx') VMS_TO_TEST="${VMS_TO_TEST:+$VMS_TO_TEST }${VM_OSX}";;
        '--all-sunos') VMS_TO_TEST="${VMS_TO_TEST:+$VMS_TO_TEST }${VM_SUNOS}";;
        '--test') shift && VMS_TO_TEST="$1";;
        '--test-cleanup') cleanup_vms ${VM_ALL} ; exit 0;;
        '--get-boxes') get_boxes ; exit 0;;
        '-h'|'--help'|'') Help;;
        '-V'|'--version') printf '%s v%s\n' "${0##*/}" "${VERSION}"; exit 0;;
        *) printf '%s is not a valid option.\n' "$1"; exit 1;;
    esac

    shift
done

run_tests $VMS_TO_TEST
