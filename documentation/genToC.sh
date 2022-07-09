#!/bin/bash

tgt=$1

[ -f "$tgt" ] || exit 127

echo "Generate TOC for $tgt file"
perl -i -ne '/^- \[.*\]\(\#/ or print' $tgt 

tmpFile=/tmp/temp.TXT
[ -f "$tmpFile" ] && rm -f $tmpFile
grep -E '^##' $tgt | grep -vE '(Table )' | while IFS= read -r chapter; do
    chapter=$(echo $chapter | sed -E 's/#//g;s/^\s+//g')
    nchapter=$(echo $chapter | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | tr '#' ' ')
    echo "- [${chapter}](#${nchapter})"
done > $tmpFile

perl -i -pe 's/<TOC>//g;s/(## Table des matières)/$1\n<TOC>\n/g;s/(## Table of contents*)/$1\n<TOC>\n/g' $tgt

perl -MFile::Slurp -pe 'BEGIN {$r = read_file("/tmp/temp.TXT"); chomp($r)}  s/<TOC>/$r/ge' -i $tgt

perl -i -ane '$n=(@F==0) ? $n+1 : 0; print if $n<=1' $tgt