#!/bin/sh

# This file is licensed under the BSD-3-Clause license.
# See the AUTHORS and LICENSE files for more information.

SSH_KEY=~/.ssh/id_rsa
LOCAL='false'
FULL='false'
REVERSE='false'

# FUNCTIONS
Help() {
    cat << EOF
${0##*/} v${VERSION}

Syntax:
${0##*/} common [ options ] ...

OPTIONS:
  -b           = list of source (to be backed up) snapshots from zfs list -t snap pool/fs command
  -d           = lsit of destination (to store backup) snapshots from zfs list -t snap pool/fs command
  -h           = Print this help and exit
  #-l          = indicates this will be a backup to a local zfs file system and ssh is not neededuser
  -v           = Verbose output

LINKS:
  website:          http://www.zfsnap.org
  repository:       https://github.com/zfsnap/zfsnap
  bug tracking:     https://github.com/zfsnap/zfsnap/issues

EOF
    Exit 0
}

# main loop; get options, perform backup of filesystem(s)
while [ -n "$1" ]; do
    OPTIND=1
    while getopts b:d:hv OPT; do
        case "$OPT" in
            b) SOURCESNAPS="$OPTARG";;
            d) DESTINATIONSNAPS="$OPTARG";;
            h) Help;;
            #l) LOCAL='true';;#enables backing up to a local filesystem
            v) VERBOSE='true';;

            :) Fatal "Option -${OPTARG} requires an argument.";;
           \?) Fatal "Invalid option: -${OPTARG}.";;
        esac
    done

    # discard all arguments processed thus far
    shift $(($OPTIND - 1))
    
	SNAPS1="$1"
	SNAPS2="$2"

    printf "$1\n\n$2"    
    #find common snapshot
    #FindCommonSnapshot "${SOURCESNAPS[*]}" "${DESTINATIONSNAPS[*]}" && COMMONSNAP=$RETVAL
        
    
done


