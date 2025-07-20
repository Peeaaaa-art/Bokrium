import { defineConfig } from 'vite'
import RubyPlugin from 'vite-plugin-ruby'

export default defineConfig({
  plugins: [
    RubyPlugin(),
  ],
  publicDir: false, // 不要なpublic配信を防止（例：app/javascriptなど）
  build: {
    outDir: 'public/vite-assets', // Railsが静的配信できる場所
    emptyOutDir: true,            // 毎回クリーンビルド
    sourcemap: false,             // 本番ではsource map非出力（安全・軽量）
  }
})