#!/bin/bash
set -euo pipefail

# Usage: bash genSop.sh <target_hosts> <script_file> [functional_slug]
# Example: bash genSop.sh lab1 setup_db.sh setup_database

target_hosts="${1:-}"
script_file="${2:-}"
slug="${3:-}"
force="${force:-0}"

if [ -z "$target_hosts" ] || [ -z "$script_file" ]; then
    echo "Usage: $0 <target_hosts> <script_file> [functional_slug]" >&2
    exit 1
fi

if [ ! -f "$script_file" ]; then
    echo "Error: script file not found: $script_file" >&2
    exit 1
fi

# If no slug is provided, use the script filename
if [ -z "$slug" ]; then
    slug=$(basename "${script_file%.*}")
fi

file_en="${slug}.md"

if [ "$force" = "1" ]; then
    rm -f "$file_en"
fi

echo "GENERATING $file_en"

# Check if profile exists (one level up)
if [ -f "../profile" ]; then
    # shellcheck disable=SC1091
    source ../profile
else
    echo "Warning: profile not found at ../profile"
fi

# Metadata extraction
extract_metadata() {
    local key="${1:-}"
    { grep "##${key}: " "$script_file" || true; } | sed "s/^##${key}: //g"
}

title_en=$(extract_metadata "title_en")
goals_en=$(extract_metadata "goals_en" | sed 's/ \/ /\n/g')

echo "TITLE EN: $title_en"
echo "GOALS EN: $goals_en"

result_content=$(mktemp)
trap 'rm -f "$result_content"' EXIT

echo "Executing script remotely: vssh_exec ${target_hosts} ${script_file}"
# Note: vssh_exec must be available in the environment (e.g., from profile)
vssh_exec "${target_hosts}" "${script_file}" 2>&1 | tee "$result_content"

# Generate English Document
if [ ! -f "$file_en" ]; then
    {
        echo "# Standard Operation: $title_en"
        echo ""
        echo "## Table of contents"
        echo "<TOC>"
        echo ""
        echo "## Main document target"
        if [ -n "$goals_en" ]; then
            printf '%s\n' "$goals_en" | while IFS= read -r line; do echo ">  * $line"; done
        fi
        echo ""
        echo "## Scripted and remote update procedure"
        echo "| Step | Description | User | Command |"
        echo "| --- | --- | --- | --- |"
        echo "| 1 | Load utilities functions | root | # source profile |"
        echo "| 2 | Execute generic script remotely | root | # vssh_exec ${target_hosts} ${script_file} |"
        echo "| 3 | Check return code | root | echo \$? (0) |"
        echo ""
        echo "## Update Procedure example remotely"
        echo "\`\`\`bash"
        echo "# vssh_exec ${target_hosts} ${script_file}"
        cat "$result_content"
        echo "# echo \$?"
        echo "0"
        echo "\`\`\`"
    } > "$file_en"
fi

# Refresh TOCs and Index
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
bash "$SCRIPT_DIR/genAllToC.sh"
bash "$SCRIPT_DIR/genReadme.sh"
