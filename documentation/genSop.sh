#!/bin/bash

# Usage: sh genSop.sh <target_hosts> <script_file> [functional_slug]
# Example: sh genSop.sh lab1 setup_db.sh setup_database

target_hosts=$1
script_file=$2
slug=$3
force=${force:-0}

# If no slug is provided, use the script filename
[ -z "$slug" ] && slug=$(basename "${script_file%.*}")

file_en="${slug}.md"
file_fr="${slug}_fr.md"

[ "$force" = "1" ] && rm -f "$file_en" "$file_fr"

echo "GENERATING $file_en and $file_fr"

# Check if profile exists (one level up)
if [ -f "../profile" ]; then
    source ../profile
else
    echo "Warning: profile not found at ../profile"
fi

# Metadata extraction
extract_metadata() {
    local key=$1
    grep "##${key}: " "$script_file" | sed "s/^##${key}: //g"
}

title_en=$(extract_metadata "title_en")
title_fr=$(extract_metadata "title_fr")
goals_en=$(extract_metadata "goals_en" | sed 's/ \/ /\n/g')
goals_fr=$(extract_metadata "goals_fr" | sed 's/ \/ /\n/g')

echo "TITLE EN: $title_en"
echo "TITLE FR: $title_fr"
echo "GOALS EN: $goals_en"
echo "GOALS FR: $goals_fr"

result_content=$(mktemp)

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
        echo "$goals_en" | while IFS= read -r line; do echo ">  * $line"; done
        echo ""
        echo "## Scripted and remote update procedure"
        echo "| Step | Description | User | Command |"
        echo "| --- | --- | --- | --- |"
        echo "| 1 | Load utilities functions  | root | # source profile |"
        echo "| 2 | Execute generic script remotely  | root | # vssh_exec ${target_hosts} ${script_file} |"
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

# Generate French Document
if [ ! -f "$file_fr" ]; then
    {
        echo "# Opération Standard : $title_fr"
        echo ""
        echo "## Table des matières"
        echo "<TOC>"
        echo ""
        echo "## Objectifs du document"
        echo "$goals_fr" | while IFS= read -r line; do echo ">  * $line"; done
        echo ""
        echo "## Procédure scriptée à distance via le protocole SSH"
        echo "| Etape | Description | Utilisateur | Commande |"
        echo "| --- | --- | --- | --- |"
        echo "| 1 | Chargement des fonctions utilitaires | root | # source profile |"
        echo "| 2 | Exécution du script générique à distance | root | # vssh_exec ${target_hosts} ${script_file} |"
        echo "| 3 | Vérifier le code retour | root | echo \$? (0) |"
        echo ""
        echo "## Exemple de procédure à distance par script"
        echo "\`\`\`bash"
        echo "# vssh_exec ${target_hosts} ${script_file}"
        cat "$result_content"
        echo "# echo \$?"
        echo "0"
        echo "\`\`\`"
    } > "$file_fr"
fi

# Cleanup
rm -f "$result_content"

# Refresh TOCs and Indices
SCRIPT_DIR=$(dirname "$0")
sh "$SCRIPT_DIR/genAllToC.sh"
sh "$SCRIPT_DIR/genReadme.sh"