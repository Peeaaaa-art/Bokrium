import { defineConfig } from 'vite'
import RubyPlugin from 'vite-plugin-ruby'

export default defineConfig({
  plugins: [RubyPlugin()],
  cacheDir: '/tmp/.vite',
  build: {
    outDir: 'public/vite',
    emptyOutDir: true,
    sourcemap: false,
    assetsDir: 'assets',
  },
})