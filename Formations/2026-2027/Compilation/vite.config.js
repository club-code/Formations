import { defineConfig } from 'vite';

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
  base: './',
  plugins: [reloadOnMarkdown],
  preview: {
    allowedHosts: ['formations.clubcode.fr'],
  },
});
