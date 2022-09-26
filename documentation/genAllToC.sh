#!/bin/bash

echo "----------------------"
for mdfile in *.md; do  
    sh ./genToC.sh $mdfile
done
echo "----------------------"