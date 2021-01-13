# vim: set ft=bash

function bypass_enabled {
    local -i status=1

    case "${GIT_BYPASS_ALL,,}" in
        1|y|yes|true) status=0; printf "Bypassing all file-specific checks: GIT_BYPASS_ALL=%s" "${GIT_BYPASS_ALL}";;
    esac
    return "${status}"
}
