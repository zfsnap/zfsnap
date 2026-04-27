# This file is licensed under the BSD-3-Clause license.
# See the AUTHORS and LICENSE files for more information.
#
# website:          http://www.zfsnap.org
# repository:       https://github.com/zfsnap/zfsnap
# bug tracking:     https://github.com/zfsnap/zfsnap/issues

# Put zsh in POSIX mode
[ -n "${ZSH_VERSION-}" ] && emulate -R sh

# COMMANDS
ZFS_CMD=$(command -v zfs)
ZPOOL_CMD=$(command -v zpool)

if [ -z "$ZFS_CMD" ] || [ -z "$ZPOOL_CMD" ]; then
    Fatal 'Unable to find zfs and/or zpool commands. Please ensure they are installed and in your PATH.'
fi

# VARIABLES
TTL='1m'                            # default snapshot TTL
VERBOSE='false'                     # Verbose output?
DRY_RUN='false'                     # Dry run?
POOLS=''                            # List of pools
FS_LIST=''                          # List of all ZFS filesystems
SKIP_POOLS=''                       # List of pools to skip

readonly DATE_PATTERN='[12][90][0-9][0-9]-[01][0-9]-[0-3][0-9]_[0-2][0-9].[0-5][0-9].[0-5][0-9]'
TEST_MODE=${TEST_MODE:-false}       # When set to "true", Exit won't really exit
TIME_FORMAT='%Y-%m-%d_%H.%M.%S'     # date/time format for snapshot creation and comparison
RETVAL=''                           # used by functions so we can avoid spawning subshells
