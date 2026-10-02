#!/usr/bin/env bash

set -euo pipefail

cd "$(dirname "$0")/../.."

declare -A seen

for dir in Formations/*/*/; do
  [ -d "$dir" ] || continue
  dir=${dir%/}
  if [ -f "$dir/package.json" ] && jq -e '.scripts.build' "$dir/package.json" >/dev/null; then
    kind=vite
  elif [ -f "$dir/slides.pdf" ]; then
    kind=pdf
  else
    continue
  fi
  info="$dir/formation.json"
  [ -f "$info" ] || info=/dev/null
  line=$(jq -nc --arg dir "$dir" --arg kind "$kind" --slurpfile info "$info" \
    '($dir | split("/")) as $path
     | ($path[-2] + "/" + ($info[0].slug // ($path[-1] | ascii_downcase))) as $slug
     | {dir: $dir, slug: $slug, id: ($slug | gsub("/"; "_")), kind: $kind}')
  slug=$(jq -r .slug <<<"$line")
  if [ -n "${seen[$slug]:-}" ]; then
    echo "Slug « $slug » utilisé par ${seen[$slug]} et $dir : change le champ \"slug\" de formation.json" >&2
    exit 1
  fi
  seen[$slug]=$dir
  echo "$line"
done
