#!/usr/bin/env bash
set -x
set -eo pipefail

function buildnvim() {
    # Make sure I cloned the thing.
    local nvim_dir="$HOME/Code/neovim"
    [ ! -d "$nvim_dir" ] && echo "Silly girl, you haven't cloned neovim..." && return

    # Go to the neovim directory.
    cd "$nvim_dir" || { printf '\n========== COULD NOT CD TO NEOVIM DIRECTORY ==========\n' && return; }

    if ! git diff --exit-code; then
        printf '\n========== LOCAL NEOVIM CHANGES! ==========\n'
        return
    fi

    # Checkout the master branch.
    git checkout master

    # Fetch the latest changes.
    git fetch upstream master

    # Log the upstream commits.
    git --no-pager log --decorate=short --pretty=short master..upstream/master

    # Merge the latest changes.
    git merge upstream/master

    # Clear the previous build.
    local install_dir="$HOME/.nvim"
    rm -rf "$install_dir"
    make distclean

    # Go back to the given commit or HEAD.
    local commit="${1:-HEAD}"
    printf '\n========== CHECKING OUT COMMIT %s... ==========\n' "$commit"
    git reset --hard "$commit"

    # Apply my fold column patch.
    printf '\n========== APPLYING FOLDCOLUMN PATCH... ==========\n'
    local patch_file="$nvim_dir/foldcolumn.patch"
    cat <<'EOF' > "$patch_file"
diff --git a/src/nvim/drawline.c b/src/nvim/drawline.c
index 5ccfb24b8..d3978d511 100644
--- a/src/nvim/drawline.c
+++ b/src/nvim/drawline.c
@@ -436,10 +436,8 @@ void fill_foldcolumn(win_T *wp, foldinfo_T foldinfo, linenr_T lnum, int attr, in
       symbol = wp->w_p_fcs_chars.foldopen;
     } else if (first_level == 1) {
       symbol = wp->w_p_fcs_chars.foldsep;
-    } else if (first_level + i <= 9) {
-      symbol = schar_from_ascii('0' + first_level + i);
     } else {
-      symbol = schar_from_ascii('>');
+      symbol = schar_from_ascii(' ');
     }

     if (out_buffer) {
EOF
    git apply "$patch_file"
    rm -f "$patch_file"

    # Build.
    make CMAKE_BUILD_TYPE=RelWithDebInfo CMAKE_INSTALL_PREFIX="$install_dir" install

    # Remove the patched changes.
    git checkout .
}

buildnvim "$@"
