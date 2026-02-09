#!/bin/bash
# utils.git.sh - Git aliases and helpers for dbscripts

# Git aliases
alias gst='git status'
alias grm='git rm -f'
alias gadd='git add'
alias gcm='git commit -m'
alias gps='git push'
alias gpl='git pull'
alias glg='git log'
alias gmh='git log --follow -p --'
alias gbl='git blame'
alias grs='git reset --soft HEAD~1'
alias grh='git reset --hard HEAD~1'

gunt() {
    git status | \
    grep -vE '(Changes to be committed:| to publish your local commits|git add|git restore|On branch|Your branch|Untracked files|nclude in what will b|but untracked files present|no changes added to commit|modified:|deleted:|Changes not staged for commit)' |\
    sort | uniq | \
    xargs -n 1 $*
}
alias gad='git status | grep deleted:  | cut -d: -f2 | xargs -n1 git rm -f'
alias gadd='git add'
alias gam='git status | grep modified: | cut -d: -f2 | xargs -n 1 git add'
