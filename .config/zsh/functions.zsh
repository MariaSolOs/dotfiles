function buildnvim() {
    # Make sure I cloned the thing.
    local nvim_dir="$HOME/Code/neovim"
    [ ! -d "$nvim_dir" ] && echo "Silly girl, you haven't cloned neovim..." && return
    echo "\n========== NEOVIM DIRECTORY: $nvim_dir ==========\n"

    # cd and save the CWD in the stack.
    pushd $nvim_dir

    if ! git diff --exit-code; then
        echo "\n========== LOCAL NEOVIM CHANGES! ==========\n"
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

    # Clear the cache.
    rm -rf build

    # Go back to the given commit or HEAD.
    local commit="${1:-HEAD}"
    echo "\n========== CHECKING OUT COMMIT $commit... ==========\n"
    git reset --hard "$commit"

    # Apply my fold column patch.
    echo "\n========== APPLYING FOLDCOLUMN PATCH... ==========\n"
    local patch_file="$nvim_dir/foldcolumn.patch"
    rm -f "$patch_file"
    cat <<'EOF' > "$patch_file"
diff --git a/src/nvim/drawline.c b/src/nvim/drawline.c
index e1550e0ec..78e5917b7 100644
--- a/src/nvim/drawline.c
+++ b/src/nvim/drawline.c
@@ -431,12 +431,8 @@ size_t fill_foldcolumn(char *p, win_T *wp, foldinfo_T foldinfo, linenr_T lnum)
     if (foldinfo.fi_lnum == lnum
         && first_level + i >= foldinfo.fi_low_level) {
       symbol = wp->w_p_fcs_chars.foldopen;
-    } else if (first_level == 1) {
-      symbol = wp->w_p_fcs_chars.foldsep;
-    } else if (first_level + i <= 9) {
-      symbol = '0' + first_level + i;
     } else {
-      symbol = '>';
+      symbol = ' ';
     }
 
     len = utf_char2bytes(symbol, &p[char_counter]);
EOF
    git apply "$patch_file"
    rm -f "$patch_file"

    # Build.
    make CMAKE_BUILD_TYPE=RelWithDebInfo CMAKE_EXTRA_FLAGS="-DCMAKE_INSTALL_PREFIX=$HOME/nvim"
    make install

    # Remove the patched changes.
    git checkout .

    # Push to my fork if I just updated from HEAD.
    if [ -z "$1" ]; then
        echo "\n========== PUSHING CHANGES TO FORK... ==========\n"
        git push origin master
    fi

    # Go back to where I was.
    popd
}
