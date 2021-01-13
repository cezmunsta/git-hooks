# git-hooks: reusable hooks for git repos

This is a set of shell-specific hooks, plus a series of helper libraries
to enable easy sharing of client-side hooks along with a standardised
framework.

## Installation

To add the hooks to an existing repository, thus enabling linting and other
processing during your commits, simply symlink to this repository from
the `.git/` subdirectory of your project.

```sh
$ git clone <my project>
$ mv <my project>/.git/hooks{,.examples}
$ ln -sf /path/to/git-hooks <my project>/.git/hooks
$ ls -lad .git/hooks
lrwxrwxrwx 1 user user 33 Jan 13 13:34 .git/hooks -> /home/user/workspace/git-hooks
$ ls -l
```

You can also use the installer script if you have BASH available:
```sh
$ git clone <my project>
$ cd <my project>
$ bash /path/to/git-hooks/install.sh
Successfully installed hooks in '.'
```

Additionally, you can install to one or more repositories from a parent directory:
```sh
$ git clone <my project>
$ bash /path/to/git-hooks/install.sh
1) EXIT
2) ALL
3) demo
#? 3
Installing hooks into demo
Successfully installed hooks in 'demo'
#? 1
Exiting program as requested
```

## Overrides

The following overrides are supported:

- `GIT_BYPASS_ALL`: skip all validation, use with care
- `GIT_BYPASS_PYTHON`: skip validation of `python` code
- `GIT_BYPASS_SHELL`: skip validation of shell scripts

For each of these, the following enable bypassing:
- `1`
- `ok|OK`
- `true`
- `y|Y`

### Example:
```sh
# Just changed README.md a want to speed up commit
$ GIT_BYPASS_ALL=1 git commit README.md
```
