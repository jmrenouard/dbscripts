#!/bin/bash

cd /logiciels/datastax/zeppelin/notebook


git status


echo " * delete removed Zeppelin notebooks"
NBRM=$(git status | grep -E "(supprim|deleted)\s*:"|wc -l)
if [ $NBRM -gt 0 ]; then
	git status | grep -E "(supprim|deleted)\s*:" |cut -d: -f2 | xargs -n1 git rm -f
else
	echo "Nothing to delete"
fi

NBUP=$(git status | grep -E 'modifi.*:'|wc -l)

echo " * Commit modified Zeppelin notebooks"
if [ $NBUP -gt 0 ]; then
	git status | grep -E 'modifi.*:' | cut -d: -f2 | xargs -n 1 git add
else
	echo "Nothind to update"
fi
echo " * Adding new Zeppelin notebooks"
git add *
git add */*
git add */*/*

git commit -m "Newly updates Zeppelin notebook at $(date +%Y%m%d-%H%M%S)"

git push
