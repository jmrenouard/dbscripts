#!/bin/bash
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
cd "$SCRIPT_DIR"
echo "----------------------"
find . -type f -name "*.md" ! -name "*README*" | sort | while IFS= read -r mdfile; do
    bash "$SCRIPT_DIR/genToC.sh" "$mdfile"
done
echo "----------------------"
