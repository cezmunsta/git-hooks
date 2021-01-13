# vim: set ft=bash

function get_shell_files {
    git diff --cached --name-only --diff-filter=ACM | grep -E '\.(ba|z)?sh$'
}

function shell_bypass_enabled {
    local -i status=1

    case "${GIT_BYPASS_SHELL,,}" in
        1|y|yes|true) status=0
    esac
    return "${status}"
}

function check_shell {
    local shellcheck=

    shellcheck="$(which shellcheck 2>&1)"

    if test -x "${shellcheck}"; then
        shell_bypass_enabled || check_shell_files "${shellcheck}"
    else
        printf "** WARNING ** Unable to execute shellcheck: %s\n" "${shellcheck}"
    fi
}

function check_shell_files {
    local -i lint_issues=0
    local -a errors=()

    local shellcheck="${1}"
    local shellchecklog="lint.log"

    printf "\nValidating shell scripts:\n"

    for file in $(get_shell_files); do

        ("${shellcheck}" --shell=bash --color=never --external-sources "${file}" >"${shellchecklog}" 2>&1)

        if test $? -ne 0 ; then
            errors[${lint_issues}]="$(printf "\n - fix lint issues: %s\n\n%s\n" "${file}" "$(grep -E '^[RCWEF]:' "${shellchecklog}" | sed 's/^/   /g')")"
            let lint_issues="lint_issues + 1"
        fi
    done

    if test ${lint_issues} -gt 0; then
        for error in "${errors[@]}"; do
            printf " - %s\n" "${error}"
        done
        printf "\nPlease fix lint issues before committing\n\n"
        exit 2
    else
        printf " OK\n\n"
    fi
}
