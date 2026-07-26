#!/usr/bin/env bash

set -euo pipefail

repo_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)
cd -- "$repo_dir"

printf 'file\tline\tlanguage\n'
while IFS= read -r file; do
  awk '
    /^```/ {
      if (!inside) {
        language = substr($0, 4)
        gsub(/^[[:space:]]+|[[:space:]]+$/, "", language)
        if (language == "") language = "untagged"
        printf "%s\t%d\t%s\n", FILENAME, NR, language
      }
      inside = !inside
    }
  ' "$file"
done < <(find README.md docs -type f -name '*.md' -print | LC_ALL=C sort)
