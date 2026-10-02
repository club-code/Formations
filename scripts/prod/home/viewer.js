// Lecteur de slides PDF (pages générées par build-pdf.sh), avec pdf.js.
// Navigation façon reveal.js : flèches, espace, début/fin, F pour le plein écran,
// clic ou glissement sur la slide. Le numéro de slide est gardé dans l'URL (#3).
import * as pdfjs from './pdfjs/pdf.min.js';

pdfjs.GlobalWorkerOptions.workerSrc = new URL('pdfjs/pdf.worker.min.js', import.meta.url).href;

const deck = document.querySelector('[data-deck]');
const stage = deck.querySelector('.stage');
const screen = stage.querySelector('canvas');
const current = deck.querySelector('[data-current]');
const total = deck.querySelector('[data-total]');
const progress = deck.querySelector('.deck-progress span');

let doc;
let page = 1;
let cache = new Map(); // n° de slide → promesse du canvas rendu à la taille actuelle

const render = (n) => {
  if (!cache.has(n)) {
    cache.set(
      n,
      doc.getPage(n).then(async (p) => {
        const base = p.getViewport({ scale: 1 });
        const fit = Math.min(stage.clientWidth / base.width, stage.clientHeight / base.height);
        // Largeur entière en pixels : sinon un liseré du fond blanc de pdf.js déborde au bord
        const width = Math.floor(base.width * fit * devicePixelRatio);
        const viewport = p.getViewport({ scale: width / base.width });
        const canvas = document.createElement('canvas');
        canvas.width = width;
        canvas.height = Math.floor(viewport.height);
        await p.render({ canvas, viewport, background: 'transparent' }).promise;
        return canvas;
      }),
    );
  }
  return cache.get(n);
};

const show = async (n) => {
  page = Math.min(Math.max(n, 1), doc.numPages);
  current.textContent = page;
  progress.style.transform = `scaleX(${page / doc.numPages})`;
  history.replaceState(null, '', `#${page}`);

  const shown = page;
  const canvas = await render(shown);
  if (shown !== page) return;
  screen.width = canvas.width;
  screen.height = canvas.height;
  screen.style.width = `${canvas.width / devicePixelRatio}px`;
  screen.style.height = `${canvas.height / devicePixelRatio}px`;
  screen.getContext('2d').drawImage(canvas, 0, 0);
  stage.classList.add('is-ready');

  // Les voisines sont préparées pour que la navigation soit instantanée
  for (const next of [page + 1, page - 1]) {
    if (next >= 1 && next <= doc.numPages) render(next);
  }
};

const go = (delta) => doc && show(page + delta);

// Plein écran (repli en CSS là où l'API n'existe pas, comme sur iPhone)
const isFullscreen = () => document.fullscreenElement === deck || deck.classList.contains('is-fake-fullscreen');
const toggleFullscreen = () => {
  if (deck.requestFullscreen) {
    if (document.fullscreenElement) document.exitFullscreen();
    else deck.requestFullscreen().catch(() => {});
  } else {
    deck.classList.toggle('is-fake-fullscreen');
    document.documentElement.classList.toggle('no-scroll', isFullscreen());
    deck.dispatchEvent(new Event('fullscreen-toggle'));
  }
};

const syncFullscreen = () => {
  deck.classList.toggle('is-fullscreen', isFullscreen());
  for (const button of deck.querySelectorAll('[data-action="fullscreen"]')) {
    button.setAttribute('aria-pressed', isFullscreen());
  }
  stage.focus({ preventScroll: true });
};
document.addEventListener('fullscreenchange', syncFullscreen);
deck.addEventListener('fullscreen-toggle', syncFullscreen);

// En plein écran, la barre et le curseur disparaissent quand la souris ne bouge plus
let idle;
deck.addEventListener('pointermove', () => {
  deck.classList.remove('is-idle');
  clearTimeout(idle);
  idle = setTimeout(() => deck.classList.add('is-idle'), 2500);
});

document.addEventListener('click', (e) => {
  const action = e.target.closest('[data-action]')?.dataset.action;
  if (action === 'prev') go(-1);
  else if (action === 'next') go(1);
  else if (action === 'fullscreen') toggleFullscreen();
});

document.addEventListener('keydown', (e) => {
  if (e.ctrlKey || e.metaKey || e.altKey || e.target.closest('input, textarea')) return;
  const keys = {
    ArrowRight: () => go(1),
    ArrowDown: () => go(1),
    PageDown: () => go(1),
    ' ': () => go(e.shiftKey ? -1 : 1),
    n: () => go(1),
    ArrowLeft: () => go(-1),
    ArrowUp: () => go(-1),
    PageUp: () => go(-1),
    p: () => go(-1),
    Home: () => doc && show(1),
    End: () => doc && show(doc.numPages),
    f: toggleFullscreen,
    F: toggleFullscreen,
    Escape: () => deck.classList.contains('is-fake-fullscreen') && toggleFullscreen(),
  };
  if (!keys[e.key] || (e.target.closest('a, button') && (e.key === ' ' || e.key === 'Enter'))) return;
  e.preventDefault();
  keys[e.key]();
});

// Clic : tiers gauche = précédente, reste = suivante. Glissement horizontal sur mobile.
let start;
stage.addEventListener('pointerdown', (e) => (start = { x: e.clientX, y: e.clientY }));
stage.addEventListener('pointerup', (e) => {
  if (!start || e.target.closest('button')) return;
  const dx = e.clientX - start.x;
  const dy = e.clientY - start.y;
  start = null;
  if (Math.abs(dx) > 50 && Math.abs(dx) > Math.abs(dy)) return go(dx < 0 ? 1 : -1);
  if (Math.abs(dx) < 10 && Math.abs(dy) < 10) {
    const { left, width } = stage.getBoundingClientRect();
    go(e.clientX - left < width / 3 ? -1 : 1);
  }
});

// Nouvelle taille → nouveau rendu, net à toutes les résolutions
let resize;
new ResizeObserver(() => {
  clearTimeout(resize);
  resize = setTimeout(() => {
    if (!doc) return;
    cache = new Map();
    show(page);
  }, 120);
}).observe(stage);

try {
  doc = await pdfjs.getDocument({
    url: deck.dataset.deck,
    wasmUrl: new URL('pdfjs/wasm/', import.meta.url).href,
  }).promise;
  const first = (await doc.getPage(1)).getViewport({ scale: 1 });
  stage.style.setProperty('--ratio', `${first.width} / ${first.height}`);
  total.textContent = doc.numPages;
  deck.classList.add('is-loaded');
  await show(parseInt(location.hash.slice(1), 10) || 1);
} catch (err) {
  console.error(err);
  deck.classList.add('is-error');
}
