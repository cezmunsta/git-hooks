#!/bin/bash
#
# An example hook script to verify what is about to be committed.
# Called by "git commit" with no arguments.  The hook should
# exit with non-zero status after issuing an appropriate message if
# it wants to stop the commit.
#
# To enable this hook, rename this file to "pre-commit".
# shellcheck disable=SC2155
declare -a HELPERS=()
declare -r HOOKS_DIR="$(realpath "$(dirname "${0}")")"
export HOOKS_DIR

mapfile -t HELPERS < <(find .git/hooks/helpers -maxdepth 1 -type d -not -name helpers -exec basename {} \;)

function msg {
    printf "%s\n" "${*}"
}

function warn {
    msg "*** WARNING ***" "${@}"
}

function error {
    msg "*** ERROR ***" "${@}"
}

function info {
    msg "*** INFO ***" "${@}"
}

function check_wc {
    if man wc | grep -q coreutils; then
        wc -c
    else
        wc -c | grep -oE '[0-9]+'
    fi
}


if git rev-parse --verify HEAD >/dev/null 2>&1
then
   against=HEAD
else
   # Initial commit: diff against an empty tree object
   against=4b825dc642cb6eb9a060e54bf8d69288fbee4904
fi

# If you want to allow non-ASCII filenames set this variable to true.
allownonascii=$(git config --bool hooks.allownonascii)

# Redirect output to stderr.
exec 1>&2

# Cross platform projects tend to avoid non-ASCII filenames; prevent
# them from being added to the repository. We exploit the fact that the
# printable range starts at the space character and ends with tilde.
if [ "$allownonascii" != "true" ] &&
   # Note that the use of brackets around a tr range is ok here, (it's
   # even required, for portability to Solaris 10's /usr/bin/tr), since
   # the square bracket bytes happen to fall in the designated range.
   test "$(git diff --cached --name-only --diff-filter=A -z $against |
     LC_ALL=C tr -d '[ -~]\0' | check_wc)" != "0"
then
   cat <<\EOF
Error: Attempt to add a non-ASCII file name.

This can cause problems if you want to work with people on other platforms.

To be portable it is advisable to rename the file.

If you know what you are doing you can disable this check using:

  git config hooks.allownonascii true
EOF
   exit 1
fi

if [ -n "${DEBUG}" ]; then
    set -o xtrace
fi

# File-specific tasks
if test -f .git/hooks/helpers/functions.bash; then
    # shellcheck disable=SC1091
    source .git/hooks/helpers/functions.bash
else
    warn "Unable to access helper functions"
fi

if ! bypass_enabled; then
    for ft in "${HELPERS[@]}"; do
        if test -f ".git/hooks/helpers/${ft}/functions.bash"; then
            # shellcheck disable=SC1090,SC1091
            source ".git/hooks/helpers/${ft}/functions.bash"
            if test -z "$(get_"${ft}"_files)"; then
                continue
            fi
            "check_${ft}"
        else
            warn "Unable to access helper functions"
        fi
    done
fi

# If there are whitespace errors, print the offending file names and fail.
exec git diff-index --check --cached $against --
