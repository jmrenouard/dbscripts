#!/bin/bash

echo "----------------------"
find . -type f -name "*.md" | grep -v "README" | while read -r mdfile; do
    sh ./genToC.sh "$mdfile"
done
echo "----------------------"