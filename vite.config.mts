import { defineConfig } from 'vite'
import RubyPlugin from 'vite-plugin-ruby'

export default defineConfig({
  plugins: [
    RubyPlugin({
      publicOutputDir: 'assets',
    }),
  ],
  publicDir: false,
  build: {
    outDir: 'public/vite',
    emptyOutDir: true,
    sourcemap: false,
  },
})