
SSH_KEY=~/.ssh/id_rsa
#EMAIL=none@none
user=$USER
LOCAL='false'
FULL='false'

# FUNCTIONS
Help() {
    cat << EOF
${0##*/} v${VERSION}

Syntax:
${0##*/} destroy [ options ] zpool/filesystem ...

OPTIONS:
  -b           = source (to be backed up) zfs pool and filesystem, pool_name/filesystem_name
  -d           = destination (to store backup) zfs pool and filesystem, pool_name/filesystem_name
  #-e		   = email address to send notification to
  #-f 		   = enable sendin full backup rather than incremental
  -h           = Print this help and exit
  -i		   = remote zfs systems IP address or DNS name
  #-l		   = indicates this will be a backup to a local zfs file system and ssh is not needed
  -k 		   = ssh key to be used to authenticate to remote zfs system; default ~/.ssh/id_rsa
  -n           = Dry-run. Perform a trial run with no backup actually performed
  -R		   = source zfs system ssh's to destination and sends snapshot instead of default destination zfs sytem ssh'ing to source and telling it to send the snapshot back
  -s           = Skip pools that are resilvering
  -S           = Skip pools that are scrubbing
  -u 		   = user for authentication via ssh to remote zfs system; default current user
  -v           = Verbose output

LINKS:
  website:          http://www.zfsnap.org
  repository:       https://github.com/zfsnap/zfsnap
  bug tracking:     https://github.com/zfsnap/zfsnap/issues

EOF
    #Exit 0
}

# main loop; get options, perform backup of filesystem(s)
while [ -n "$1" ]; do
    OPTIND=1
    while getopts b:d:e:f:hk:nRsSu:v OPT; do
        case "$OPT" in
            b) SOURCEFS='$OPTARG';;
            d) DESTINATIONFS='$OPTARG';;
            #e) EMAIL='$OPTARG';;#could possibly have utility email results of backup upon completion, would require user to already have setup mail
            #f) FULL='TRUE';;#this flag can be used to perform a full backup when full backup option is implemented
            h) Help;;
			i) REMOTE='$OPTARG';;#remote system ip or dns address
            k) SSH_KEY='$OPTARG';;#ssh key to access remote system
			#l) LOCAL='true';;#enables backing up to a local filesystem
            n) DRY_RUN='true';;
            R) REVERSE='true';;
            s) PopulateSkipPools 'resilver';;
            S) PopulateSkipPools 'scrub';;
			u) user='$OPTARG';;
            v) VERBOSE='true';;

            :) Fatal "Option -${OPTARG} requires an argument.";;
           \?) Fatal "Invalid option: -${OPTARG}.";;
        esac
    done

    # discard all arguments processed thus far
    shift $(($OPTIND - 1))
	
	#test to see if SSH_KEY specified exists as long as this is not a local backup
	if ! $LOCAL; then
		if [ ! -r $SSH_KEY ]; then
			Fatal "'$SSH_KEY' does not exist or cannot be read!"
		fi
	fi
	
	#test to see if pool/filesytem provided is vaild
	#can currently only be performed for the local filesystem
	#would be much simpler if only supported running this command on backup system
	if $REVERSE; then
		#can only check sourcefs as it is the fs expected on the local machine
		FSExists "$SOURCEFS" || Fatal "'$SOURCEFS' does not exist!"
		
		#create list of local snapshots
		ListLocalSnapshots $SOURCEFS && SOURCESNAPS=$RETVAL
		
		#create list of remote snapshots
		ListRemoteSnapshots $SSH_KEY $user $REMOTE $DESTINATIONFS && DESTINATIONSNAPS=$RETVAL
		
		#find common snapshot
		FindCommonSnapshot "${SOURCESNAPS[*]}" "${DESTINATIONSNAPS[*]}" && COMMONSNAP=$RETVAL
		
	else
		#can only check destination fs as it is the fs expected on the local machine
		FSExists "$DESTINATIONFS" || Fatal "'$DESTINATIONFS' does not exist!"
		
		#create list of local snapshots
		ListLocalSnapshots $DESTINATIONFS && DESTINATIONSNAPS=$RETVAL
		
		#create list of remote snapshots
		ListRemoteSnapshots $SSH_KEY $user $REMOTE $SOURCEFS && SOURCESNAPS=$RETVAL
		
		#find common snapshot
		FindCommonSnapshot "${DESTINATIONSNAPS[*]}" "${SOURCESNAPS[*]}" && COMMONSNAP=$RETVAL
		
	fi
	
	
	if [ -n $COMMONSNAP ]; then
		#find latest source snapshot
		LatestSnap $SOURCESNAPS && LATESTSNAP=$RETVAL
		
		if [ "$LATESTSNAP" = "$COMMONSNAP" ]; then
			Fatal "No backup required, latest snap $LATESTSNAP, on source and the common snap, $COMMONSNAP, on the destination are the same"
		fi
		
		SNAP_SEND="SendSnapshots $SSH_KEY $user $REMOTE $SOURCEFS $DESTINATIONFS $COMMONSNAP $LATESTSNAP"
        if IsFalse "$DRY_RUN"; then
            if $SNAP_SEND >&2; then
                IsTrue $VERBOSE && printf '%s ... DONE\n' "$SNAP_SEND"
            else
                IsTrue $VERBOSE && printf '%s ... FAIL\n' "$SNAP_SEND"
            fi
        else
            printf '%s\n' "$SNAP_SEND"
        fi
		
		
	else
		Fatal "No common snapshot found!"
	fi
	
done


