#!/bin/bash

set -o errexit
set -o errtrace
set -o nounset

SCRIPTDIR="$(dirname "$(realpath "${0}")")"
SCRIPTNAME="$(basename "${0}")"

function find_repos {
    local repo=

    if [ "${#}" -eq 0 ]; then
        echo "EXIT"
        echo "ALL"
    fi
    find . -maxdepth 2 -type d -name .git | while read -r repo; do
        rp="$(realpath "${repo}")"; dn="$(dirname "${rp}")"
        printf "%s\n" "$(basename "${dn}")"
    done
}

function install_hooks {
    local project="${1}"

    mv "${project}/.git/hooks" "${project}/.git/hooks.examples"
    ln -sf "${SCRIPTDIR}" "${project}/.git/hooks"

    if ! test -f "${project}/.git/hooks/${SCRIPTNAME}"; then
        printf "Unable to find '%s' in '%s', exiting\n" "${SCRIPTNAME}" "${project}/.git/hooks"
        return 1
    fi

    if [[ ! -L "${project}/.git/hooks/pre-commit" ]] || \
       [[ "$(realpath "${project}/.git/hooks/pre-commit")" != "$(realpath "${project}/.git/hooks/pre-commit.bash")" ]]; then
        ln -sf "$(realpath "${project}/.git/hooks/pre-commit.bash")" "${project}/.git/hooks/pre-commit"
    else
        printf "\tskipping symlink for '%s', already present\n" "${project}"
    fi
    printf "Successfully installed hooks in '%s'\n" "${project}"
    return 0
}

if [ ! -d .git ]; then
    select item in $(find_repos); do
        case "${item}" in
            ALL)  find_repos nomenu | while read -r repo; do
                      install_hooks "${repo}";
                  done;
                  exit 0
                  ;;
            EXIT) echo "Exiting program as requested"; exit 0
                  ;;
            *)    printf "Installing hooks into %s\n" "${item}";
                  install_hooks "${item}"
        esac
    done
else
    install_hooks .
fi
