#!/bin/bash

target_hosts=$1
script_file=$2
file_md=$3
[ -z "$file_md" ] && file_md=$(basename ${script_file%.*})

[ "$force" = "1" ] && rm -f ${file_md}.md ${file_md}_fr.md

echo "GENERATING ${file_md}.md and ${file_md}_fr.md"
source ../profile

title_en="$(grep '##title_en: ' $script_file | perl -pe 's/^##title_en: //g')"
title_fr="$(grep '##title_fr: ' $script_file | perl -pe 's/^##title_fr: //g')"

goals_en="$(grep '##goals_en: ' $script_file | perl -pe 's/^##goals_en: //g' | perl -pe 's/ \/ /\n/g')"
goals_fr="$(grep '##goals_fr: ' $script_file | perl -pe 's/^##goals_fr: //g' | perl -pe 's/ \/ /\n/g')"


echo "TITLE EN: $title_en"
echo "TITLE FR: $title_fr"
echo "GOALS EN: $goals_en"
echo "GOALS FR: $goals_fr"

result_content=$(mktemp)

echo "vssh_exec ${target_hosts} ${script_file} 2>&1 | tee $result_content"

vssh_exec ${target_hosts} ${script_file} 2>&1 | tee $result_content

if [ ! -f "${file_md}.md" ]; then
echo "# Standard Operation: $title_en

## Table of contents
<TOC>

## Main document target
" > ${file_md}.md

echo "${goals_en}" | while IFS= read -r line; do
echo ">  * $line"
done >> ${file_md}.md

echo "## Scripted and remote update procedure
| Step | Description | User | Command |
| --- | --- | --- | --- |
| 1 | Load utilities functions  | root | # source profile |
| 2 | Execute generic script remotly  | root | # vssh_exec ${target_hosts} ${script_file} |
| 3 | Check return code | root | echo $? (0) |

##  Update Procedure example remotely
\`\`\`bash
# vssh_exec ${target_hosts} ${script_file}">> ${file_md}.md

cat ${result_content} >>${file_md}.md

echo "# echo $?
0

\`\`\`
">> ${file_md}.md
fi

if [ ! -f "${file_md}_fr.md" ]; then
echo "# Opération Standard : $title_fr

## Table des matières
<TOC>

## Objectifs du document
" > ${file_md}_fr.md

echo "${goals_fr}" | while IFS= read -r line; do
echo ">  * $line"
done >> ${file_md}_fr.md

echo "## Procédure scriptées à distance via SSH
| Etape | Description | Utilisateur | Commande |
| --- | --- | --- | --- |
| 1 | Load utilities functions  | root | # source profile |
| 2 | Execute generic script remotly  | root | # vssh_exec ${target_hosts} ${script_file} |
| 3 | Vérifier le code retour  | root | echo $? (0) |

##  Exemple de procédure à distance par script
\`\`\`bash
# vssh_exec ${target_hosts} ${script_file}">> ${file_md}_fr.md

cat ${result_content} >>${file_md}_fr.md

echo "# echo $?
0

\`\`\`
">> ${file_md}_fr.md
fi


sh genToc.sh ${file_md}.md 
sh genToc.sh ${file_md}_fr.md

sh genReadme.sh