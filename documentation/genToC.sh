#!/bin/bash
set -euo pipefail

tgt="${1:-}"

[ -n "$tgt" ] && [ -f "$tgt" ] || exit 127

tmpFile=$(mktemp)
trap 'rm -f "$tmpFile"' EXIT

echo "Generate TOC for $tgt file"
perl -i -ne '/^- \[.*\]\(\#/ or print' "$tgt"

{ grep -E '^##' "$tgt" || true; } | { grep -vE '(Table )' || true; } | while IFS= read -r chapter; do
    chapter=$(printf '%s\n' "$chapter" | sed -E 's/^#+[[:space:]]*//')
    nchapter=$(printf '%s\n' "$chapter" | tr '[:upper:]' '[:lower:]' | tr -cd '[:alnum:] _-' | tr ' ' '-')
    printf -- '- [%s](#%s)\n' "$chapter" "$nchapter"
done > "$tmpFile"

perl -i -pe 's/<TOC>//g;s/(## Table of contents)[ \t]*/$1\n<TOC>\n/gi' "$tgt"

TOC_FILE="$tmpFile" perl -i -pe 'BEGIN { open my $fh, "<", $ENV{TOC_FILE} or die $!; local $/; $r = <$fh>; close $fh; chomp($r); } s/<TOC>/$r/g' "$tgt"

perl -i -ane '$n=(@F==0) ? $n+1 : 0; print if $n<=1' "$tgt"
