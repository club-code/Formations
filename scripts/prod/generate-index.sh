#!/usr/bin/env bash

set -euo pipefail

root=${1:?Usage : $0 <racine web>}
here=$(cd "$(dirname "$0")" && pwd)

months=(janv. févr. mars avr. mai juin juil. août sept. oct. nov. déc.)

info() {
  local json="$root/$1/formation.json"
  [ -f "$json" ] || return 0
  jq -r "$2 | @html" "$json"
}

entries=$(
  for page in "$root"/*/*/index.html; do
    [ -f "$page" ] || continue
    slug=${page#"$root"/}
    slug=${slug%/index.html}
    date=$(info "$slug" '.date // ""')
    if ! [[ $date =~ ^[0-9]{4}-(0[1-9]|1[0-2])-[0-9]{2}$ ]]; then
      [ -n "$date" ] && echo "$slug : date « $date » ignorée (format attendu AAAA-MM-JJ)" >&2
      date=0000-00-00
    fi
    printf '%s\t%s\t%s\n' "${slug%%/*}" "$date" "$slug"
  done | sort -t$'\t' -k1,1r -k2,2r -k3,3
)

years=$(cut -f1 <<<"$entries" | sed '/^$/d' | uniq -c | awk '{ print $2 "\t" $1 }')

group() {
  local year=$1 n=$2 cards=$3
  local label="formations"
  [ "$n" -eq 1 ] && label="formation"
  groups+="
        <section class=\"year-group\" id=\"annee-$year\" data-year=\"$year\" aria-labelledby=\"titre-$year\">
          <h2 class=\"year-title reveal\" id=\"titre-$year\">${year/-/–} <span class=\"year-count\">$n $label</span></h2>
          <ol class=\"formations\">$cards
          </ol>
        </section>"
}

groups=""
cards=""
count=0
current=""
while IFS=$'\t' read -r year date slug; do
  [ -n "$slug" ] || continue
  if [ "$year" != "$current" ]; then
    [ -n "$current" ] && group "$current" "$year_count" "$cards"
    current=$year
    cards=""
    year_count=0
  fi
  count=$((count + 1))
  year_count=$((year_count + 1))
  num=$(printf '%02d' "$year_count")
  title=$(info "$slug" '.title // ""')
  [ -n "$title" ] || title=$(sed -n 's:.*<title>\(.*\)</title>.*:\1:p' "$root/$slug/index.html" | head -n 1)
  title=${title:-$slug}
  desc=$(info "$slug" '.description // ""')
  format=$(info "$slug" '.format // ""')
  tags=$(info "$slug" '.keywords // [] | if type == "string" then split(",") else . end | .[] | gsub("^\\s+|\\s+$"; "") | select(. != "")')

  poster='<div class="poster-frame notched placeholder" aria-hidden="true"><img src="_home/mark.svg" alt=""></div>'
  style=""
  for ext in webp png jpg jpeg svg; do
    if [ -f "$root/$slug/affiche.$ext" ]; then
      poster="<div class=\"poster-frame notched\"><img class=\"poster\" src=\"$slug/affiche.$ext\" alt=\"Affiche de la formation $title\" decoding=\"async\"></div>"
      style=" style=\"--poster: url('$slug/affiche.$ext')\""
      break
    fi
  done

  meta_line="<span>/$slug/</span>"
  cta="Ouvrir les slides"
  if [ "$format" = pdf ]; then
    meta_line+="<span>PDF</span>"
    cta="Voir le PDF"
  fi
  if [ "$date" != 0000-00-00 ]; then
    IFS=- read -r y m d <<<"$date"
    meta_line="<span><time datetime=\"$date\">$((10#$d)) ${months[10#$m - 1]} $y</time></span>$meta_line"
  fi

  if [ -n "$tags" ]; then
    tags="
              <span class=\"tags\">$(while IFS= read -r tag; do printf '<span class="tag">%s</span>' "$tag"; done <<<"$tags")</span>"
  fi

  cards+="
        <li class=\"reveal\" style=\"--d: $(( count < 6 ? count + 1 : 7 ))00ms\">
          <a class=\"panel notched card\" href=\"$slug/\"$style>
            <div class=\"panel-inner\">
              $poster
              <div class=\"card-body\">
                <span class=\"card-index\" aria-hidden=\"true\">$num</span>
                <p class=\"card-meta\">$meta_line</p>
                <h3 class=\"card-title\">$title</h3>${desc:+
                <p class=\"card-desc\">$desc</p>}$tags
                <span class=\"btn btn-primary notched card-cta\">
                  $cta
                  <svg width=\"14\" height=\"14\" viewBox=\"0 0 14 14\" fill=\"none\" aria-hidden=\"true\"><path d=\"M1 7h12M8 2l5 5-5 5\" stroke=\"currentColor\" stroke-width=\"1.5\"/></svg>
                </span>
              </div>
            </div>
          </a>
        </li>"

done <<<"$entries"
[ -n "$current" ] && group "$current" "$year_count" "$cards"

menu=""
if [ "$count" -gt 0 ]; then
  items="
              <li><button type=\"button\" data-year=\"\" aria-pressed=\"true\">Toutes les années <span>$count</span></button></li>"
  while IFS=$'\t' read -r year n; do
    items+="
              <li><button type=\"button\" data-year=\"$year\" aria-pressed=\"false\">${year/-/–} <span>$n</span></button></li>"
  done <<<"$years"
  menu="
        <div class=\"year-menu\" hidden>
          <button type=\"button\" class=\"btn btn-ghost notched btn-nav year-toggle\" aria-expanded=\"false\" aria-controls=\"year-list\">
            <span data-year-label>Années</span>
            <svg width=\"10\" height=\"10\" viewBox=\"0 0 10 10\" fill=\"none\" aria-hidden=\"true\"><path d=\"M1 3l4 4 4-4\" stroke=\"currentColor\" stroke-width=\"1.5\"/></svg>
          </button>
          <div class=\"year-list panel notched\" id=\"year-list\" hidden>
            <ul class=\"panel-inner\">$items
            </ul>
          </div>
        </div>"
fi

if [ "$count" -eq 0 ]; then
  groups='
        <ol class="formations">
          <li class="panel notched empty"><div class="panel-inner">Aucune formation pour le moment. Reviens bientôt !</div></li>
        </ol>'
  overline="Formations"
elif [ "$count" -eq 1 ]; then
  overline="1 formation en ligne"
else
  overline="$count formations en ligne"
fi

year=$(date +%Y)

assets=$(mktemp -d "$root/.home.XXXXXX")
cp -r "$here/home/." "$assets/"
chmod -R a+rX "$assets"
rm -rf "$root/_home"
mv "$assets" "$root/_home"

tmp=$(mktemp "$root/.index.XXXXXX")
cat > "$tmp" <<HTML
<!doctype html>
<html lang="fr">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Formations · Club Code</title>
  <meta name="description" content="Les supports de présentation des formations du Club Code, le club de programmation de Télécom SudParis.">
  <meta name="theme-color" content="#08080d">
  <meta property="og:title" content="Formations · Club Code">
  <meta property="og:description" content="Les supports de présentation des formations du Club Code.">
  <meta property="og:site_name" content="Club Code">
  <link rel="icon" type="image/svg+xml" href="_home/mark.svg">
  <link rel="preload" href="_home/fonts/clash-display-600.woff2" as="font" type="font/woff2" crossorigin>
  <link rel="preload" href="_home/fonts/satoshi-400.woff2" as="font" type="font/woff2" crossorigin>
  <link rel="stylesheet" href="_home/style.css">
</head>
<body>
  <header class="nav" id="nav">
    <div class="container nav-row">
      <a class="brand" href="https://clubcode.fr" aria-label="Club Code">
        <img src="_home/mark.svg" alt="" width="44" height="25">
        <span class="brand-name">Club Code</span>
        <span class="brand-sub">formations</span>
      </a>
      <div class="actions">
        <a class="nav-link" href="https://clubcode.fr">clubcode.fr ↗</a>$menu
        <a class="btn btn-ghost notched btn-nav" href="https://discord.clubcode.fr" target="_blank" rel="noopener">Discord</a>
      </div>
    </div>
  </header>

  <main>
    <section class="hero" id="catalogue">
      <div class="hero-grid" aria-hidden="true"></div>
      <div class="container">
        <div class="hero-head">
          <p class="overline reveal">$overline</p>
          <h1 class="reveal" style="--d: 80ms">Les formations du <span class="accent">Club Code</span>.</h1>
        </div>$groups
      </div>
    </section>
  </main>

  <footer class="footer">
    <div class="container footer-grid">
      <div class="footer-brand">
        <img src="_home/logo.svg" alt="Club Code" width="232" height="66">
        <p>Le club de programmation de Télécom SudParis.</p>
      </div>
      <nav class="footer-links" aria-label="Liens">
        <span class="footer-links-title">Liens</span>
        <a href="https://clubcode.fr">clubcode.fr</a>
        <a href="https://discord.clubcode.fr" target="_blank" rel="noopener">Discord</a>
        <a href="https://github.clubcode.fr" target="_blank" rel="noopener">GitHub</a>
      </nav>
    </div>
    <div class="container footer-legal">
      <span>© 2015-$year Club Code</span>
      <span class="footer-mono">&lt;/&gt;</span>
    </div>
  </footer>

  <div class="grain" aria-hidden="true"></div>

  <script>
    const nav = document.getElementById('nav');
    const onScroll = () => nav.classList.toggle('is-scrolled', scrollY > 24);
    addEventListener('scroll', onScroll, { passive: true });
    onScroll();

    // Menu des années : n'affiche que les formations de l'année choisie
    const menu = document.querySelector('.year-menu');
    if (menu) {
      const toggle = menu.querySelector('.year-toggle');
      const list = menu.querySelector('.year-list');
      const label = menu.querySelector('[data-year-label]');
      const items = [...list.querySelectorAll('[data-year]')];
      const open = (state) => {
        list.hidden = !state;
        toggle.setAttribute('aria-expanded', state);
      };
      const show = (year) => {
        const item = items.find((item) => item.dataset.year === year) ?? items[0];
        year = item.dataset.year;
        for (const i of items) i.setAttribute('aria-pressed', i === item);
        label.textContent = year ? item.firstChild.textContent.trim() : 'Années';
        for (const group of document.querySelectorAll('.year-group')) {
          group.hidden = year !== '' && group.dataset.year !== year;
        }
        const url = new URL(location.href);
        if (year) url.searchParams.set('annee', year);
        else url.searchParams.delete('annee');
        history.replaceState(null, '', url);
      };
      toggle.addEventListener('click', () => open(list.hidden));
      list.addEventListener('click', (e) => {
        const item = e.target.closest('[data-year]');
        if (!item) return;
        show(item.dataset.year);
        open(false);
        toggle.focus();
        scrollTo({ top: 0 });
      });
      document.addEventListener('click', (e) => !menu.contains(e.target) && open(false));
      // Tabulation hors du menu (les clics à l'extérieur sont gérés juste au-dessus)
      menu.addEventListener('focusout', (e) => e.relatedTarget && !menu.contains(e.relatedTarget) && open(false));
      menu.addEventListener('keydown', (e) => {
        if (e.key === 'Escape' && !list.hidden) {
          open(false);
          toggle.focus();
        } else if ((e.key === 'ArrowDown' || e.key === 'ArrowUp') && !list.hidden) {
          e.preventDefault();
          const i = items.indexOf(document.activeElement);
          const next = i < 0 ? 0 : (i + (e.key === 'ArrowDown' ? 1 : items.length - 1)) % items.length;
          items[next].focus();
        }
      });
      show(new URLSearchParams(location.search).get('annee') ?? '');
      menu.hidden = false;
    }
  </script>
</body>
</html>
HTML
chmod 644 "$tmp"
mv "$tmp" "$root/index.html"
