#!/bin/bash

SCRIPT_DIR=$(dirname "$0")
echo "----------------------"
find . -type f -name "*.md" | grep -v "README" | while read -r mdfile; do
    sh "$SCRIPT_DIR/genToC.sh" "$mdfile"
done
echo "----------------------"