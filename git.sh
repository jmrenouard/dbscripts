
##########################################
# Functions GIT
##########################################
alias gst="git status"
alias ga="git add"
alias gam="git status | grep modified: | cut -d: -f2 | xargs -n 1 git add"
alias gad="git status | grep deleted:  | cut -d: -f2 | xargs -n1 git rm -f"

greset()
{
	git fetch --all
	git reset --hard origin/master
	git pull
}


alias | grep -q gcm && unalias gcm
gcm()
{
        git commit -m "$@"
}
alias mdcleanup="perl -i -pe 's/\[\d;\d{2}m//g;s/\[0m//g;s/\[\?2004h//g'"
alias rl=reload
alias gst="git status"
alias ga="git add"
alias gam="git status | grep -E 'modifi.*:' | cut -d: -f2 | xargs -n 1 git add"
alias gad="git status | grep '(supprim.*|deleted):'  | cut -d: -f2 | xargs -n1 git rm -f"

gpull()
{
    local verb=${1:-"pull"}
    for rep in ${2:-"$HOME/GIT_REPOS"}/*; do 
        if [ ! -d "$rep/.git" ]; then
            title1 "$rep NOT .git REPO"
            continue
        fi
        title1 $rep PULLING CHANGES
        ( 
            cd $rep
            git config pull.rebase false 
            git $verb
        )
    done
}
alias | grep -q gcm && unalias gcm
gcm()
{
        git commit -m "$@"
}

