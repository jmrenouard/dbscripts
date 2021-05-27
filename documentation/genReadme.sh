#!/bin/bash

echo "# List of Standard Operation Sheet" > README.md

for mdf in $(find . -type f -iname '*.md' | grep -v '_fr'); do
	title=$(head -1 $mdf | cut -d: -f2)
	echo " *  [$title]($mdf)"
done >> README.md


echo "# Liste des procédures opérationnelles standards" >> README.md

for mdf in $(find . -type f -iname '*.md' | grep '_fr'); do
	title=$(head -1 $mdf | cut -d: -f2)
	echo " *  [$title]($mdf)"
done >> README.md
