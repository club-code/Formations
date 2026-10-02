#!/usr/bin/env bash

set -euo pipefail

src=${1:?Usage : $0 <dossier de la formation> <dossier de sortie>}
out=${2:?Usage : $0 <dossier de la formation> <dossier de sortie>}

[ -f "$src/slides.pdf" ] || { echo "$src/slides.pdf introuvable" >&2; exit 1; }

info="$src/formation.json"


field() {
  [ -f "$info" ] || return 0
  jq -r --arg k "$1" '.[$k] // empty | (if type == "array" then join(", ") else tostring end) | @html' "$info"
}

title=$(field title)
title=${title:-$(basename "$(cd "$src" && pwd)")}
desc=$(field description)

mkdir -p "$out"
cp "$src/slides.pdf" "$out/slides.pdf"

if [ -f "$info" ]; then
  jq '. + {format: "pdf"}' "$info" > "$out/formation.json"
else
  echo '{"format": "pdf"}' > "$out/formation.json"
fi
poster=""
for ext in webp png jpg jpeg svg; do
  if [ -f "$src/affiche.$ext" ]; then
    cp "$src/affiche.$ext" "$out/"
    poster="affiche.$ext"
    break
  fi
done

size=$(du -k "$out/slides.pdf" | awk '{ s = $1 / 1024; if (s < 1) printf "%d Ko", $1; else { v = sprintf("%.1f", s); sub(/\./, ",", v); print v " Mo" } }')

metas=""
[ -n "$desc" ] && metas="
  <meta name=\"description\" content=\"$desc\">"

fallback_poster=""
[ -n "$poster" ] && fallback_poster="<img src=\"$poster\" alt=\"\">"

tmp=$(mktemp "$out/.index.XXXXXX")
cat > "$tmp" <<HTML
<!doctype html>
<html lang="fr">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>$title</title>$metas
  <meta name="theme-color" content="#08080d">
  <link rel="icon" type="image/svg+xml" href="/_home/mark.svg">
  <link rel="stylesheet" href="/_home/style.css">
</head>
<body class="viewer-page">
  <header class="nav is-scrolled">
    <div class="container nav-row">
      <a class="brand" href="/" aria-label="Toutes les formations">
        <img src="/_home/mark.svg" alt="" width="44" height="25">
        <span class="brand-name">Club Code</span>
        <span class="brand-sub">formations</span>
      </a>
      <div class="actions">
        <a class="nav-link" href="/">← Formations</a>
      </div>
    </div>
  </header>

  <main class="viewer container">
    <div class="viewer-head">
      <div>
        <p class="overline reveal">Formation · PDF</p>
        <h1 class="reveal" style="--d: 80ms">$title</h1>
      </div>
      <div class="viewer-actions reveal" style="--d: 160ms">
        <button class="btn btn-primary notched" type="button" data-action="fullscreen">
          Plein écran <kbd>F</kbd>
        </button>
        <a class="btn btn-ghost notched" href="slides.pdf" download>
          Télécharger <span class="btn-note">PDF · $size</span>
        </a>
      </div>
    </div>

    <div class="panel notched deck reveal" style="--d: 240ms" data-deck="slides.pdf">
      <div class="panel-inner">
        <div class="stage" tabindex="0" aria-label="Slides, flèches pour naviguer">
          <canvas></canvas>
          <p class="stage-status stage-loading">Chargement des slides…</p>
          <div class="stage-status stage-error">
            $fallback_poster
            <p>Impossible d'afficher les slides ici.</p>
            <a class="btn btn-primary notched" href="slides.pdf" target="_blank" rel="noopener">Ouvrir le PDF</a>
          </div>
        </div>
        <div class="deck-bar">
          <button class="icon-btn" type="button" data-action="prev" aria-label="Slide précédente">
            <svg width="16" height="16" viewBox="0 0 16 16" fill="none" aria-hidden="true"><path d="M15 8H2M7 3 2 8l5 5" stroke="currentColor" stroke-width="1.5"/></svg>
          </button>
          <span class="deck-count"><span data-current>1</span> / <span data-total>…</span></span>
          <button class="icon-btn" type="button" data-action="next" aria-label="Slide suivante">
            <svg width="16" height="16" viewBox="0 0 16 16" fill="none" aria-hidden="true"><path d="M1 8h13M9 3l5 5-5 5" stroke="currentColor" stroke-width="1.5"/></svg>
          </button>
          <span class="deck-progress" aria-hidden="true"><span></span></span>
          <span class="deck-hint">← → pour naviguer</span>
          <button class="icon-btn" type="button" data-action="fullscreen" aria-label="Plein écran" aria-pressed="false">
            <svg class="enter" width="16" height="16" viewBox="0 0 16 16" fill="none" aria-hidden="true"><path d="M1 6V1h5M10 1h5v5M15 10v5h-5M6 15H1v-5" stroke="currentColor" stroke-width="1.5"/></svg>
            <svg class="exit" width="16" height="16" viewBox="0 0 16 16" fill="none" aria-hidden="true"><path d="M6 1v5H1M15 6h-5V1M10 15v-5h5M1 10h5v5" stroke="currentColor" stroke-width="1.5"/></svg>
          </button>
        </div>
      </div>
    </div>
    <noscript><p class="viewer-noscript">JavaScript est désactivé : <a href="slides.pdf">ouvre le PDF directement</a>.</p></noscript>
  </main>

  <script type="module" src="/_home/viewer.js"></script>
</body>
</html>
HTML
chmod 644 "$tmp"
mv "$tmp" "$out/index.html"
