function gcb -d 'git - Checkout branch with fzf'
    git for-each-ref --format='%(refname:short)' refs/heads | fzf --height 10% --layout=reverse --select-1 | xargs git checkout
end
