# vim: set ft=bash

function get_python_files {
    git diff --cached --name-only --diff-filter=ACM | grep -E '\.py[co]?$'
}

function python_bypass_enabled {
    local -i status=1

    case "${GIT_BYPASS_PYTHON,,}" in
        1|y|yes|true) status=0
    esac
    return "${status}"
}

function check_python {
    local linter=

    case "${GIT_PYTHON_LINTER:-ruff}" in
        pylint|ruff) linter="$(command -v "${GIT_PYTHON_LINTER}" 2>&1)" ;;
        *) echo "Unsupported linter: ${GIT_PYTHON_LINTER}"; exit 2
    esac

    if test -x "$(which "${linter}")"; then
        python_bypass_enabled || check_python_files_"$(basename "${linter}")" "${linter}"
    else
        printf "** WARNING ** Unable to execute linter: %s\n" "${linter}"
    fi

}

function check_python_files_pylint {
    local -i lint_issues=0
    local -a errors=()

    # shellcheck disable=SC2155
    local py_version="$(env python --version)"
    local pylint="${1}"
    local pylintrc="${HOOKS_DIR}/etc/python/.pylintrc"
    local pylintlog="lint.log"
    local pylintargs=""

    if [[ "${py_version}" =~ ^Python\ 2 ]]; then
        pylintargs+="--py3k"
        pylint="pylint"
    fi

    printf "\nPython version: %s" "${py_version}"
    printf "\nValidating Python with %s --rcfile=%s --reports=no %s:\n\n" \
        "${pylint}" "${pylintrc}" "${pylintargs}"

    for file in $(get_python_files); do
        if [[ "${file:(-2)}" != "py" ]]; then
            printf " - ignoring file: %s\n" "${file}"
            continue
        fi

        (${pylint} --rcfile="${pylintrc}" --reports=no ${pylintargs} "${file}" >"${pylintlog}" 2>&1)

        if test $? -ne 0 ; then
            errors[${lint_issues}]="$(printf " - fix lint issues: %s\n\n%s\n" "${file}" "$(grep -E '^[RCWEF]:' "${pylintlog}" | sed 's/^/   /g')")"
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

function check_python_files_ruff {
    local -i lint_issues=0
    local -a errors=()

    # shellcheck disable=SC2155
    local py_version="$(env python --version)"
    local ruff="${1}"
    local ruffrc="${HOOKS_DIR}/etc/python/.ruff.toml"
    local rufflog="lint.log"
    local ruffargs=""

    if [[ "${GIT_PYTHON_LINT_CONFIG:-undefined}" != "undefined" ]] && [[ -f "${GIT_PYTHON_LINT_CONFIG}" ]]; then
        ruffrc="${GIT_PYTHON_LINT_CONFIG}"
    fi

    printf "\nPython version: %s" "${py_version}"
    printf "\nValidating Python with %s check --config=%s %s:\n\n" \
        "${ruff}" "${ruffrc}" "${ruffargs}"

    for file in $(get_python_files); do
        if [[ "${file:(-2)}" != "py" ]]; then
            printf " - ignoring file: %s\n" "${file}"
            continue
        fi

        ("${ruff}" check --config="${ruffrc}" ${ruffargs} "${file}" >"${rufflog}" 2>&1)

        if test $? -ne 0 ; then
            errors[${lint_issues}]="$(printf " - fix lint issues: %s\n\n%s\n" "${file}" "$(grep -E '^[RCWEF]:' "${rufflog}" | sed 's/^/   /g')")"
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
