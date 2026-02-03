source "https://rubygems.org"

ruby "~> 4.0.1"

gem "rails", "~> 8.1.2"

gem "puma"

gem "turbo-rails"

gem "propshaft"

gem "vite_rails"

gem "view_component", "4.2.0"

gem "pg"

gem "pg_search"

gem "image_processing"

# JSON API構築用
gem "jbuilder"

gem "devise", "~> 5.0"

gem "devise-i18n"

gem "omniauth"

gem "omniauth-line"

gem "line-bot-api"

gem "omniauth-rails_csrf_protection"

gem "webauthn"

gem "rails-i18n"

gem "pagy", "~> 43.2"

gem "rack-rewrite"

gem "browser"

gem "aws-sdk-s3", "~> 1.213", require: false

gem "rakuten_web_service"

gem "dotenv-rails"

# 高速HTML/XMLパーサ（NDL API用）
gem "nokogiri"

# Markdownパーサ
gem "redcarpet"

gem "stripe"

gem "tzinfo-data", platforms: [ :windows, :jruby ]

gem "solid_cache"

# 起動高速化
gem "bootsnap", require: false

# HTTPアセット圧縮・X-Sendfile対応
gem "thruster", require: false

group :development do
  gem "letter_opener_web"
end

group :development, :test do
  gem "debug", platforms: [ :mri, :windows ], require: "debug/prelude"

  gem "brakeman", "~> 8.0", require: false

  gem "rubocop-rails-omakase", require: false

  gem "rspec-rails"

  gem "factory_bot_rails"

  gem "bullet"
end

group :development do
  gem "web-console"

  gem "dockerfile-rails"

  gem "rack-mini-profiler"
end

group :test do
  gem "capybara"

  gem "capybara-playwright-driver"

  gem "shoulda-matchers"

  gem "webmock"

  gem "rails-controller-testing"
end
