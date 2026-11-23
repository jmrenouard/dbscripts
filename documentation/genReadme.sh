#!/bin/bash
set -euo pipefail

# Target file
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
README_EN="$SCRIPT_DIR/README.md"

# Header
{
    echo "# List of Standard Operation Sheets"
    echo "This index is automatically generated. Documentation is organized by chapters (directories)."
    echo ""
} > "$README_EN"

# Process markdown files in a directory for English documentation
process_directory() {
    local dir="${1:-}"
    local output_file="${2:-}"
    local header_name="${3:-}"
    local files

    files=$(find "$dir" -maxdepth 1 -type f -name '*.md' ! -name '*_fr.md' ! -name 'README*' | sort)

    if [ -n "$files" ]; then
        echo "## $header_name" >> "$output_file"
        printf '%s\n' "$files" | while IFS= read -r mdf; do
            # Extract title from first line (stripping markdown #)
            local title rel_path
            title=$(head -n 1 "$mdf" | sed 's/^#* //')
            rel_path="${mdf#./}"
            echo " * [$title]($rel_path)" >> "$output_file"
        done
        echo "" >> "$output_file"
    fi
}

# 1. Global / Root documentation
process_directory "." "$README_EN" "General Documentation"

# 2. Subdirectories (Chapters)
directories=$(find . -maxdepth 1 -type d ! -name "." ! -name ".*" | sort)

while IFS= read -r dir; do
    [ -n "$dir" ] || continue
    dir_name=$(basename "$dir")
    process_directory "$dir" "$README_EN" "$dir_name"
done <<< "$directories"

echo "Generated $README_EN"
