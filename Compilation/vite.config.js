import { defineConfig } from 'vite';

// reveal.js charge les slides .md une seule fois au chargement de la page :
// on recharge la page entière quand l'un d'eux change.
const reloadOnMarkdown = {
  name: 'reload-on-markdown',
  configureServer(server) {
    const reload = (file) => {
      if (file.endsWith('.md')) server.ws.send({ type: 'full-reload' });
    };
    server.watcher.on('change', reload);
    server.watcher.on('add', reload);
  },
};

export default defineConfig({
  plugins: [reloadOnMarkdown],
});
