#!/bin/bash

# Target files
README_EN="README.md"
README_FR="README_fr.md"

# Headers
{
    echo "# List of Standard Operation Sheets"
    echo "This index is automatically generated. Documentation is organized by chapters (directories)."
    echo ""
} > "$README_EN"

{
    echo "# Liste des fiches d'opérations standards (SOP)"
    echo "Cet index est généré automatiquement. La documentation est organisée par chapitres (répertoires)."
    echo ""
} > "$README_FR"

# Function to process files in a directory for a specific language
process_directory() {
    dir="$1"
    lang="$2" # "en" or "fr"
    output_file="$3"
    header_name="$4"

    if [ "$lang" = "fr" ]; then
        files=$(find "$dir" -maxdepth 1 -type f -name '*_fr.md' ! -name 'README*' | sort)
    else
        files=$(find "$dir" -maxdepth 1 -type f -name '*.md' ! -name '*_fr.md' ! -name 'README*' | sort)
    fi

    if [ -n "$files" ]; then
        echo "## $header_name" >> "$output_file"
        echo "$files" | while read -r mdf; do
            # Extract title from first line (stripping markdown #)
            title=$(head -1 "$mdf" | sed 's/^#* //')
            echo " * [$title]($mdf)" >> "$output_file"
        done
        echo "" >> "$output_file"
    fi
}

# 1. Global / Root documentation
process_directory "." "en" "$README_EN" "General Documentation"
process_directory "." "fr" "$README_FR" "Documentation Générale"

# 2. Subdirectories (Chapters)
# Find all directories that contain at least one .md file, excluding . itself
directories=$(find . -maxdepth 1 -type d ! -name "." ! -name ".*" | sort)

for dir in $directories; do
    dir_name=$(basename "$dir")
    process_directory "$dir" "en" "$README_EN" "$dir_name"
    process_directory "$dir" "fr" "$README_FR" "$dir_name"
done

echo "Generated $README_EN and $README_FR"
