#!/usr/bin/env bash

set -euo pipefail

repo_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)
cd -- "$repo_dir"

static_only=false
if [[ ${1:-} == "--static-only" ]]; then
  static_only=true
fi

failures=0

while IFS=$'\t' read -r file target; do
  [[ -n $file && -n $target ]] || continue
  if [[ $target == /* ]]; then
    candidate=$target
  else
    candidate="$(dirname -- "$file")/$target"
  fi
  if [[ ! -f $candidate ]]; then
    printf 'broken Markdown link: %s -> %s\n' "$file" "$target" >&2
    failures=$((failures + 1))
  fi
done < <(
  find README.md docs -type f -name '*.md' -print0 |
    xargs -0 perl -ne '
      while (/\]\(([^)#]+\.md)(?:#[^)]+)?\)/g) {
        print "$ARGV\t$1\n";
      }
    '
)

if rg -n -- '-vsync(?:[[:space:]]|=)|-async(?:[[:space:]]|=)' README.md docs; then
  printf 'deprecated active option found\n' >&2
  failures=$((failures + 1))
fi

if rg -n '\\[[:space:]]+#' README.md docs; then
  printf 'comment found after a line-continuation backslash\n' >&2
  failures=$((failures + 1))
fi

while IFS= read -r file; do
  if ! awk '
    /^```/ { inside = !inside }
    END { exit inside ? 1 : 0 }
  ' "$file"; then
    printf 'unbalanced fenced code block: %s\n' "$file" >&2
    failures=$((failures + 1))
  fi
done < <(find README.md docs -type f -name '*.md' -print)

if ((failures > 0)); then
  exit 1
fi

if [[ $static_only == false ]]; then
  expected_version=8.1.2
  actual_version=$(ffmpeg -version | awk 'NR == 1 { print $3 }')
  if [[ $actual_version != "$expected_version" ]]; then
    printf 'FFmpeg %s is required; found %s\n' "$expected_version" "$actual_version" >&2
    exit 1
  fi
  ffprobe -version >/dev/null
fi

block_count=$(scripts/inventory-code-blocks.sh | awk 'NR > 1 { count++ } END { print count + 0 }')
printf 'documentation checks passed (%s fenced code blocks inventoried)\n' "$block_count"
