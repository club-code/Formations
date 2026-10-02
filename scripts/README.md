# Scripts

## `prod/` : build et déploiement (CI)

Utilisés par `.github/workflows/formations.yml`. Le job de déploiement ne récupère que ce dossier.

- `list-formations.sh` : liste les formations de `Formations/<année>/<formation>/`
- `build-pdf.sh` : construit une formation PDF (page de slides avec pdf.js)
- `generate-index.sh` : génère la page d'accueil
- `home/` : style, polices, logos et lecteur PDF, copiés dans `_home/` sur le site

## `dev/` : preview locale

- `preview.sh [port]` : lance toutes les formations en hot reload sur `http://localhost:8000`, avec les mêmes URLs qu'en prod
- `dev-server.mjs` : serveur lancé par `preview.sh`

La preview réutilise les scripts de `prod/` : ce qu'on voit en local est construit comme en production.
