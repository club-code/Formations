#!/usr/bin/env bash

set -euo pipefail

port=${1:-8000}
repo=$(cd "$(dirname "$0")/../.." && pwd)
prod="$repo/scripts/prod"
site="$repo/_site"

for cmd in jq node; do
  command -v "$cmd" >/dev/null || { echo "$cmd est requis" >&2; exit 1; }
done

trap 'kill $(jobs -p) 2>/dev/null' EXIT

declare -A installed

while true; do
  rm -rf "$site"
  mkdir -p "$site"
  routes=()
  dev_port=5173

  mapfile -t formations < <("$prod/list-formations.sh" | jq -r '[.dir, .slug, .kind] | @tsv')

  for formation in "${formations[@]}"; do
    IFS=$'\t' read -r name slug kind <<<"$formation"
    dir="$repo/$name"
    echo "==> $name → /$slug/ ($kind)"
    mkdir -p "$site/$slug"

    if [ "$kind" = pdf ]; then
      "$prod/build-pdf.sh" "$dir" "$site/$slug"
      routes+=("$slug=@$dir")
      continue
    fi

    if [ -z "${installed[$dir]:-}" ]; then
      if [ -f "$dir/pnpm-lock.yaml" ]; then pm=pnpm; else pm=npm; fi
      (cd "$dir" && $pm install)
      installed[$dir]=1
    fi
    (cd "$dir" && exec node_modules/.bin/vite --base "/$slug/" --host 127.0.0.1 \
      --port "$dev_port" --strictPort --clearScreen false) &

    ln -s "$dir/index.html" "$site/$slug/index.html"
    if [ -f "$dir/formation.json" ]; then ln -s "$dir/formation.json" "$site/$slug/"; fi
    for poster in "$dir"/public/affiche.*; do
      if [ -f "$poster" ]; then ln -s "$poster" "$site/$slug/"; fi
    done

    routes+=("$slug=$dev_port")
    dev_port=$((dev_port + 1))
  done

  "$prod/generate-index.sh" "$site"

  echo "==> http://localhost:$port"
  status=0
  node "$repo/scripts/dev/dev-server.mjs" "$site" "$port" "${routes[@]}" || status=$?

  [ "$status" -eq 75 ] || exit "$status"
  kill $(jobs -p) 2>/dev/null || true
  wait 2>/dev/null || true
done
