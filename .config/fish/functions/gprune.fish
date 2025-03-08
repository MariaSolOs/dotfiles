function gprune -d 'git - Delete all branches removed in remote'
    git fetch -p && git branch -vv | awk '/: gone]/{print $1}' | xargs git branch -D
end
