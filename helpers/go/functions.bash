# vim: set ft=bash

function get_go_files {
    git diff --cached --name-only --diff-filter=ACM | grep -E '\.go$'
}

function go_bypass_enabled {
    local -i status=1

    case "${GIT_BYPASS_GO,,}" in
        1|y|yes|true) status=0
    esac
    return "${status}"
}

function check_go {
    local lint=
    lint="$(command -v go 2>&1)"
    if test -x "${lint}"; then
        go_bypass_enabled || check_go_files "${lint} vet -unusedresult -bools -copylocks -framepointer -httpresponse -json -stdmethods -printf -stringintconv -unmarshal -unreachable -unsafeptr -unusedresult "
    else
        printf "** WARNING ** Unable to execute lint: %s\n" "${lint}"
    fi
}

function check_go_files {
    local -i lint_issues=0
    local -a errors=()

    # shellcheck disable=SC2155
    local version="$(env go version)"
    local lint="${1}"
    local lintlog="lint.log"

    printf "\nGo version: %s" "${version}"
    printf "\nValidating Go with %s:\n\n" "${lint}"

    :>"${lintlog}"

    for file in $(get_go_files); do
        if [[ "${file:(-2)}" != "go" ]]; then
            printf " - ignoring file: %s\n" "${file}"
            continue
        fi

        (${lint} "${file}" >>"${lintlog}" 2>&1)

        if test $? -ne 0 ; then
            errors[${lint_issues}]="$(printf " - fix lint issues: %s\n\n%s\n" "${file}" "$(grep -E '^[RCWEF]:' "${lintlog}" | sed 's/^/   /g')")"
            lint_issues=$((lint_issues + 1))
        fi
    done

    if test ${lint_issues} -gt 0; then
        for error in "${errors[@]}"; do
            printf "%s\n" "${error}"
        done
        printf "\nPlease fix lint issues before committing\n\n"
        exit 2
    else
        printf " OK\n\n"
    fi
}
