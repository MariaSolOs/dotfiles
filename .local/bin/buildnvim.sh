#!/usr/bin/env bash
set -x
set -eo pipefail

function buildnvim() {
    # Make sure I cloned the thing.
    local nvim_dir="$HOME/Code/neovim"
    [ ! -d "$nvim_dir" ] && echo "Silly girl, you haven't cloned neovim..." && return

    # Go to the neovim directory.
    cd "$nvim_dir" || { printf '\n========== COULD NOT CD TO NEOVIM DIRECTORY ==========\n' && return; }

    local current_branch
    current_branch="$(git rev-parse --abbrev-ref HEAD)"

    if [ "$current_branch" = "master" ]; then
        # On master — discard any local changes.
        git checkout -f master
    else
        # On another branch — bail if there are local changes.
        if ! git diff --exit-code; then
            printf '\n========== LOCAL CHANGES ON BRANCH %s! ==========\n' "$current_branch"
            return
        fi
        git checkout master
    fi

    # Fetch the latest changes.
    git fetch upstream master

    # Log the upstream commits.
    git --no-pager log --decorate=short --pretty=short master..upstream/master

    # Merge the latest changes.
    git merge upstream/master

    # Go back to the given commit or HEAD.
    local commit="${1:-HEAD}"
    printf '\n========== CHECKING OUT COMMIT %s... ==========\n' "$commit"
    git reset --hard "$commit"

    # Clear the previous build.
    local install_dir="$HOME/.nvim"
    rm -rf "$install_dir"
    make distclean

    # Build.
    make CMAKE_BUILD_TYPE=RelWithDebInfo CMAKE_INSTALL_PREFIX="$install_dir" install
}

buildnvim "$@"
