function buildnvim() {
    # Make sure I cloned the thing.
    nvim_dir="$HOME/Code/neovim"
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

    # Apply my fold column patch.
    echo "\n========== APPLYING FOLDCOLUMN PATCH... ==========\n"
    patch_file="$nvim_dir/foldcolumn.patch"
    rm -f "$patch_file"
    cat <<'EOF' > "$patch_file"
diff --git a/src/nvim/drawline.c b/src/nvim/drawline.c
index 4b989fa59..655e66016 100644
--- a/src/nvim/drawline.c
+++ b/src/nvim/drawline.c
@@ -433,12 +433,8 @@ size_t fill_foldcolumn(char *p, win_T *wp, foldinfo_T foldinfo, linenr_T lnum)
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
    git reset --hard HEAD
    git apply "$patch_file"
    rm -f "$patch_file"

    # Build.
    make CMAKE_BUILD_TYPE=RelWithDebInfo CMAKE_EXTRA_FLAGS="-DCMAKE_INSTALL_PREFIX=$HOME/nvim"
    make install

    # Remove the patched changes.
    git checkout .

    # Push to my fork.
    echo "\n========== PUSHING CHANGES TO MASTER... ==========\n"
    git push origin master

    # Go back to where I was.
    popd
}
