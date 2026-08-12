import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';

// Proxy target is Traefik (localhost:80), not the api container directly — the api
// service publishes no host port in docker-compose.yml, only Traefik does. This exercises
// the same PathPrefix(/api) routing used in production. Local dev flow:
//   docker compose up traefik api postgres kafka redis   (frontend container excluded —
//                                                          this dev server replaces it)
//   npm run dev
export default defineConfig({
  plugins: [react()],
  server: {
    proxy: {
      '/api': { target: 'http://localhost', changeOrigin: true },
    },
  },
});
