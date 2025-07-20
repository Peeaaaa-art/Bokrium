source "https://rubygems.org"

ruby "~> 3.4.3"

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 📦 Rails本体・基本構成
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

gem "rails", "~> 8.0.2"

gem "puma"

gem "turbo-rails"

gem "propshaft"

gem "vite_rails"

gem "view_component", "4.0.0.rc2"

# PostgreSQLドライバ
gem "pg"
# 検索機能（PostgreSQL全文検索）
gem "pg_search"

# ActiveStorageの画像変換用
gem "image_processing"

# JSON API構築用
gem "jbuilder"

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔒 認証・セキュリティ
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

gem "devise"

gem "devise-i18n"

gem "omniauth"

gem "omniauth-line"

gem "line-bot-api"

gem "omniauth-rails_csrf_protection"

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🌍 国際化
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

gem "rails-i18n"

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔎 ページネーション・補助機能
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

gem "pagy"

gem "rack-rewrite"

# デバイス種別の判定
gem "browser"

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🌐 外部API・データ連携
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

gem "aws-sdk-s3", "~> 1.192", require: false

gem "rakuten_web_service"

gem "dotenv-rails"

# 高速HTML/XMLパーサ（NDL API用）
gem "nokogiri"

# Markdownパーサ
gem "redcarpet"

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 💰 決済・マネタイズ
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

gem "stripe"

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# ⚙️ OS依存・起動最適化
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

gem "tzinfo-data", platforms: [ :mingw, :mswin, :x64_mingw, :jruby ]

gem "solid_cache"

# 起動高速化
gem "bootsnap", require: false

# HTTPアセット圧縮・X-Sendfile対応
gem "thruster", require: false

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🧪 開発・テスト環境
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

group :development, :test do
  gem "debug", platforms: [ :mri, :mswin, :mingw, :x64_mingw ], require: "debug/prelude"

  gem "brakeman", "~> 7.1", require: false

  gem "rubocop-rails-omakase", require: false

  gem "rspec-rails"

  gem "factory_bot_rails"

  # N+1検出
  gem "bullet"

  gem "newrelic_rpm"
end

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🛠️ 開発専用
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

group :development do
  gem "web-console"
end

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🧪 テスト専用
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

group :test do
  gem "capybara"

  gem "selenium-webdriver"

  gem "shoulda-matchers"

  gem "webmock"

  gem "rails-controller-testing"
end

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 📬 開発用メール・Docker
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

gem "letter_opener"

gem "dockerfile-rails", group: :development
