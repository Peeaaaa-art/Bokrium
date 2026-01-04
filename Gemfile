source "https://rubygems.org"

ruby "~> 3.4.3"

gem "rails", "~> 8.1.0"

gem "puma"

gem "turbo-rails"

gem "propshaft"

gem "vite_rails"

gem "view_component", "4.1.1"

gem "pg"

gem "pg_search"

gem "image_processing"

# JSON API構築用
gem "jbuilder"

gem "devise"

gem "devise-i18n"

gem "omniauth"

gem "omniauth-line"

gem "line-bot-api"

gem "omniauth-rails_csrf_protection"

gem "webauthn"

gem "rails-i18n"

gem "pagy", "~> 43.0"

gem "rack-rewrite"

gem "browser"

gem "aws-sdk-s3", "~> 1.208", require: false

gem "rakuten_web_service"

gem "dotenv-rails"

# 高速HTML/XMLパーサ（NDL API用）
gem "nokogiri"

# Markdownパーサ
gem "redcarpet"

gem "stripe"

gem "tzinfo-data", platforms: [ :mingw, :mswin, :x64_mingw, :jruby ]

gem "solid_cache"

# 起動高速化
gem "bootsnap", require: false

# HTTPアセット圧縮・X-Sendfile対応
gem "thruster", require: false

gem "letter_opener"


group :development, :test do
  gem "debug", platforms: [ :mri, :mswin, :mingw, :x64_mingw ], require: "debug/prelude"

  gem "brakeman", "~> 7.1", require: false

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

  gem "selenium-webdriver"

  gem "shoulda-matchers"

  gem "webmock"

  gem "rails-controller-testing"
end
