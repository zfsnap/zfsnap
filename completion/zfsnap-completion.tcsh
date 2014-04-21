#!tcsh
#
# This file is licensed under the BSD-3-Clause license.
# See the AUTHORS and LICENSE files for more information.
#
# simple tcsh completion support for zfsnap
#   this won't provide suggestions for flags, only commands and ZFS filesystems
#

if ( -w /dev/zfs ) then
    set __ZFSNAP="zfsnap"
    set __ZFSNAP_ZFS="zfs"
else
    set __ZFSNAP="sudo zfsnap"
    set __ZFSNAP_ZFS="sudo zfs"
endif

set __zfsnap_list_commands = (snapshot destroy)

# prints zfs datasets and volumes
alias __zfsnap_list_datasets '$__ZFSNAP_ZFS list -H -t filesystem,volume -o name'

complete zfsnap \
    'p/1/$__zfsnap_list_commands/'\
    'n/destroy/`__zfsnap_list_datasets`/'\
    'n/snapshot/`__zfsnap_list_datasets`/'
