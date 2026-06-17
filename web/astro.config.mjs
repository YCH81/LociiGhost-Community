import { defineConfig } from 'astro/config';
import tailwind from '@astrojs/tailwind';

// GitHub Pages serves project pages at https://<user>.github.io/<repo>/.
// `site` + `base` together make all internal links resolve correctly
// both in production and in `astro dev`.
export default defineConfig({
    site: 'https://ych81.github.io',
    base: '/LociiGhost-Community',
    trailingSlash: 'ignore',
    integrations: [tailwind()],
    build: {
        assets: 'assets',
    },
    server: {
        port: 4321,
    },
});
