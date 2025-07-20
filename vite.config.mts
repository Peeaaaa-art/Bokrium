import { defineConfig } from 'vite'
import RubyPlugin from 'vite-plugin-ruby'

export default defineConfig({
  plugins: [
    RubyPlugin({
      publicOutputDir: '.',
    }),
  ],
  publicDir: false,
  cacheDir: '/tmp/.vite',
  build: {
    outDir: 'public/vite-assets',
    emptyOutDir: true,
    sourcemap: false,
  },
})