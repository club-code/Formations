import { execFile, execFileSync } from 'node:child_process';
import fs from 'node:fs';
import http from 'node:http';
import net from 'node:net';
import path from 'node:path';
import { promisify } from 'node:util';

const run = promisify(execFile);

const [root, port, ...routes] = process.argv.slice(2);
const targets = {}; // slug → port Vite
const sources = {}; // slug → dossier de la formation PDF
for (const route of routes) {
  const i = route.indexOf('=');
  const [slug, target] = [route.slice(0, i), route.slice(i + 1)];
  if (target.startsWith('@')) sources[slug] = target.slice(1);
  else targets[slug] = target;
}
const segments = (url) => url.split(/[/?]/).slice(1);
const slugOf = (url) => segments(url).slice(0, 2).join('/');
const targetOf = (url) => targets[slugOf(url)];

const types = {
  '.html': 'text/html; charset=utf-8',
  '.css': 'text/css; charset=utf-8',
  '.js': 'text/javascript; charset=utf-8',
  '.wasm': 'application/wasm',
  '.svg': 'image/svg+xml',
  '.woff2': 'font/woff2',
  '.pdf': 'application/pdf',
  '.png': 'image/png',
  '.jpg': 'image/jpeg',
  '.jpeg': 'image/jpeg',
  '.webp': 'image/webp',
};

const clients = new Set();
const boot = Date.now().toString(36);
const reloadScript = `<script>new EventSource('/__reload?boot=${boot}').onmessage = () => location.reload();</script>`;

const repo = path.resolve(import.meta.dirname, '../..');
const prod = path.join(repo, 'scripts', 'prod');
const stale = new Set();
let timer;
let running = Promise.resolve();
const regenerate = (slug) => {
  if (slug) stale.add(slug);
  clearTimeout(timer);
  timer = setTimeout(() => {
    running = running.then(async () => {
      try {
        for (const slug of stale) {
          stale.delete(slug);
          await run(path.join(prod, 'build-pdf.sh'), [sources[slug], path.join(root, slug)]);
          console.log(`/${slug}/ reconstruite`);
        }
        await run(path.join(prod, 'generate-index.sh'), [root]);
        console.log("Page d'accueil régénérée");
        for (const client of clients) client.write('data: reload\n\n');
      } catch (err) {
        console.error(`Échec de la génération\n${err.stderr ?? err}`);
      }
    });
  }, 100);
};

const watch = (dir, filter, onChange, recursive = false) =>
  fs
    .watch(dir, { recursive }, (_event, name) => {
      if (!name || filter(name)) onChange();
    })
    .on('error', () => {}); // dossier supprimé

const listFormations = () => execFileSync(path.join(prod, 'list-formations.sh'), { encoding: 'utf8' });
const layout = listFormations();
let layoutTimer;
const checkLayout = () => {
  clearTimeout(layoutTimer);
  layoutTimer = setTimeout(() => {
    let current;
    try {
      current = listFormations();
    } catch {
      return;
    }
    if (current === layout) return;
    console.log('==> Formations ajoutées, supprimées ou renommées : redémarrage de la preview');
    process.exit(75);
  }, 300);
};
const formations = path.join(repo, 'Formations');
const watched = new Set();
const subdirs = (dir) => {
  try {
    return fs
      .readdirSync(dir, { withFileTypes: true })
      .filter((entry) => entry.isDirectory() && !entry.name.startsWith('.'))
      .map((entry) => path.join(dir, entry.name));
  } catch {
    return [];
  }
};
const onTreeChange = () => {
  watchFormations();
  checkLayout();
};
const watchFormations = () => {
  for (const year of subdirs(formations)) {
    if (!watched.has(year)) {
      watched.add(year);
      watch(year, () => true, onTreeChange);
    }
    for (const dir of subdirs(year)) {
      if (watched.has(dir)) continue;
      watched.add(dir);
      watch(dir, (name) => ['formation.json', 'package.json', 'slides.pdf'].includes(name), checkLayout);
    }
  }
};
fs.mkdirSync(formations, { recursive: true });
watchFormations();
watch(formations, () => true, onTreeChange);

watch(prod, (name) => name === 'generate-index.sh', () => regenerate());
watch(prod, (name) => name === 'build-pdf.sh', () => Object.keys(sources).forEach(regenerate));
watch(path.join(prod, 'home'), () => true, () => regenerate(), true);
for (const slug of Object.keys(targets)) {
  const page = path.join(root, slug, 'index.html');
  if (fs.existsSync(page)) {
    const relevant = (name) => name === 'index.html' || name === 'formation.json';
    watch(path.dirname(fs.realpathSync(page)), relevant, () => regenerate());
  }
}
for (const [slug, dir] of Object.entries(sources)) {
  const relevant = (name) => ['slides.pdf', 'formation.json'].includes(name) || name.startsWith('affiche.');
  watch(dir, relevant, () => regenerate(slug));
}

const server = http.createServer((req, res) => {
  if (req.url.startsWith('/__reload')) {
    res.writeHead(200, { 'content-type': 'text/event-stream', 'cache-control': 'no-store' });
    res.write(': ok\n\n');
    if (new URL(req.url, 'http://localhost').searchParams.get('boot') !== boot) res.write('data: reload\n\n');
    clients.add(res);
    req.on('close', () => clients.delete(res));
    return;
  }

  const target = targetOf(req.url);
  if (target) {
    const upstream = http.request(
      { host: '127.0.0.1', port: target, path: req.url, method: req.method, headers: req.headers },
      (up) => {
        res.writeHead(up.statusCode, up.headers);
        up.pipe(res);
      },
    );
    upstream.on('error', () => {
      res.writeHead(502, { 'content-type': 'text/plain; charset=utf-8' });
      res.end('Serveur de dev pas encore prêt, recharge dans un instant.');
    });
    req.pipe(upstream);
    return;
  }

  const pathname = new URL(req.url, 'http://localhost').pathname;
  const slug = slugOf(pathname);
  const [first] = segments(pathname);
  if (!(pathname === '/' || first === 'index.html' || first === '_home' || slug in sources)) {
    return notFound(res);
  }
  if (slug in sources && pathname === `/${slug}`) {
    res.writeHead(301, { location: `/${slug}/` });
    return res.end();
  }
  const file = path.resolve(root, '.' + decodeURI(pathname) + (pathname.endsWith('/') ? 'index.html' : ''));
  if (!file.startsWith(path.resolve(root) + path.sep) || !fs.existsSync(file) || !fs.statSync(file).isFile()) {
    return notFound(res);
  }
  const type = types[path.extname(file)] ?? 'application/octet-stream';
  res.writeHead(200, { 'content-type': type, 'cache-control': 'no-store' });
  if (type.startsWith('text/html')) {
    res.end(fs.readFileSync(file, 'utf8').replace('</body>', `${reloadScript}\n</body>`));
  } else {
    fs.createReadStream(file).pipe(res);
  }
});

function notFound(res) {
  res.writeHead(404, { 'content-type': 'text/plain; charset=utf-8' });
  res.end('Introuvable');
}

server.on('upgrade', (req, socket, head) => {
  const target = targetOf(req.url);
  if (!target) return socket.destroy();

  const upstream = net.connect(target, '127.0.0.1', () => {
    let request = `${req.method} ${req.url} HTTP/${req.httpVersion}\r\n`;
    for (let i = 0; i < req.rawHeaders.length; i += 2) {
      request += `${req.rawHeaders[i]}: ${req.rawHeaders[i + 1]}\r\n`;
    }
    upstream.write(request + '\r\n');
    upstream.write(head);
    socket.pipe(upstream).pipe(socket);
  });
  upstream.on('error', () => socket.destroy());
  socket.on('error', () => upstream.destroy());
});

server.listen(port, '127.0.0.1');
