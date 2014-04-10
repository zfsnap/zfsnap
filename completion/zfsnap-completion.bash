#!bash
#
# bash completion support for zfsnap
#
# This file is licensed under the BSD-3-Clause license.
# See the AUTHORS and LICENSE files for more information.

if [[ -w /dev/zfs ]]; then
    __ZFSNAP="zfsnap"
    __ZFSNAP_ZFS="zfs"
else
    __ZFSNAP="sudo zfsnap"
    __ZFSNAP_ZFS="sudo zfs"
fi

# prints top-level zfsnap commands
__zfsnap_list_commands() {
    start='false'
    $__ZFSNAP -h | \
    while IFS= read line; do
        [ "$line" == 'COMMANDS:' ] && start='true' && continue

        if [ $start == 'true' ]; then
            [ -z "$line" ] && break

            line="${line#"${line%%[!\ ]*}"}" # trim leading spaces
            printf '%s\n' "${line}"
        fi
    done
}

# prints zfs datasets and volumes
__zfsnap_list_datasets() {
    $__ZFSNAP_ZFS list -H -t filesystem,volume -o name
}

# prints valid flags of a given command
__zfsnap_list_flags() {
    local cmd="$1"

    case "${cmd}" in
        destroy|snapshot|zfsnap)
            [ ${cmd} == 'zfsnap' ] && cmd=''

            start='false'
            $__ZFSNAP $cmd -h | \
            while IFS= read line; do
                [ "$line" == 'OPTIONS:' ] && start='true' && continue

                if [ $start == 'true' ]; then
                    [ -z "$line" ] && break

                    line="${line#"${line%%[!\ ]*}"}" # trim leading spaces
                    [ -z "${line##-[a-z]*}" ] && printf '%s\n' "${line:0:2}"
                fi
            done
            ;;
        *)
            return 1
            ;;
    esac
}

__zfsnap_complete() {
    COMPREPLY=() # zero out response array
    local cur="${COMP_WORDS[COMP_CWORD]}"
    local prev="${COMP_WORDS[COMP_CWORD-1]}"
    local cmd="${COMP_WORDS[1]}"

    [[ ${prev##*/} == 'zfsnap' ]] && cmd='zfsnap'

    if [[ ${cur:0:1} == '-' ]]; then
        COMPREPLY=($(compgen -W "$(__zfsnap_list_flags ${cmd})" -- "$cur"))
        return 0
    fi

    case "${cmd}" in
        destroy|snapshot)
            case "${prev}" in
                # flags which accept arguments or aren't meant to be used on datasets
                -a|-h|-F|-p|-V)
                    return 1
                    ;;
                *)
                    COMPREPLY=($(compgen -W "$(__zfsnap_list_datasets)" -- "$cur"))
                    return 0
                    ;;
            esac
            ;;
        zfsnap)
            COMPREPLY=($(compgen -W "$(__zfsnap_list_commands)" -- "$cur"))
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

complete -F __zfsnap_complete zfsnap
