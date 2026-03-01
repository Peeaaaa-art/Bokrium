import { defineConfig } from 'vite'
import RubyPlugin from 'vite-plugin-ruby'

export default defineConfig(({ mode }) => {
  const isProduction = mode === 'production'

  return {
    ...(isProduction ? { base: 'https://assets.bokrium.com/' } : {}),
    plugins: [RubyPlugin()],
    cacheDir: '/tmp/.vite',
    publicDir: false,
    server: {
      host: '0.0.0.0',
    },
    build: {
      outDir: 'public/vite',
      emptyOutDir: true,
      sourcemap: false,
      assetsDir: 'assets',
    },
  }
})
