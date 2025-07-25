import { defineConfig } from 'vite'
import RubyPlugin from 'vite-plugin-ruby'

export default defineConfig({
  base: 'https://assets.bokrium.com/',
  plugins: [RubyPlugin()],
  cacheDir: '/tmp/.vite',
  publicDir: false,
  build: {
    outDir: 'public/vite',
    emptyOutDir: true,
    sourcemap: false,
    assetsDir: 'assets',
  },
})