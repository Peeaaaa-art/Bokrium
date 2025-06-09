source "https://rubygems.org"

ruby "~> 3.4.3"
gem "rails", "~> 8.0.2"
gem "pg", "~> 1.1"
# Use Active Storage variants [https://guides.rubyonrails.org/active_storage_overview.html#transforming-images]
gem "image_processing", "~> 1.2"
# The modern asset pipeline for Rails [https://github.com/rails/propshaft]
gem "propshaft"
# Use the Puma web server [https://github.com/puma/puma]
gem "puma", ">= 5.0"
# Use JavaScript with ESM import maps [https://github.com/rails/importmap-rails]
gem "importmap-rails"
# Hotwire's SPA-like page accelerator [https://turbo.hotwired.dev]
gem "turbo-rails"
# Hotwire's modest JavaScript framework [https://stimulus.hotwired.dev]
gem "stimulus-rails"
# Build JSON APIs with ease [https://github.com/rails/jbuilder]
gem "jbuilder"

gem "sidekiq", "~> 7.2"

# 私が追加したGem
gem "devise"
gem "devise-i18n"
gem "rails-i18n", "~> 8.0"
gem "dartsass-rails"
gem "bootstrap", "~> 5.3.5"
gem "aws-sdk-s3", "~> 1.189", require: false
gem "rakuten_web_service"
gem "dotenv-rails"
gem "rexml"
gem "redcarpet", "~> 3.6", ">= 3.6.1"
gem "acts-as-taggable-on"
gem "nokogiri"
gem "pg_search"
gem "rack-rewrite"
gem "line-bot-api"
gem "omniauth"
gem "omniauth-line"
gem "omniauth-rails_csrf_protection"
gem "whenever", require: false
gem "browser"
gem "pagy"

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem "tzinfo-data", platforms: [ :mingw, :mswin, :x64_mingw, :jruby ]
# Use the database-backed adapters for Rails.cache, Active Job, and Action Cable
gem "solid_cache"
gem "solid_queue"
gem "solid_cable"
# Reduces boot times through caching; required in config/boot.rb
gem "bootsnap", require: false
# Deploy this application anywhere as a Docker container [https://kamal-deploy.org]
gem "kamal", require: false
# Add HTTP asset caching/compression and X-Sendfile acceleration to Puma [https://github.com/basecamp/thruster/]
gem "thruster", require: false

group :development, :test do
  # See https://guides.rubyonrails.org/debugging_rails_applications.html#debugging-with-the-debug-gem
  gem "debug", platforms: [ :mri, :mswin, :mingw, :x64_mingw ], require: "debug/prelude"

  # Static analysis for security vulnerabilities [https://brakemanscanner.org/]
  gem "brakeman", require: false

  # Omakase Ruby styling [https://github.com/rails/rubocop-rails-omakase/]
  gem "rubocop-rails-omakase", require: false

  gem "rspec-rails"

  gem "factory_bot_rails"
end

group :development do
  # Use console on exceptions pages [https://github.com/rails/web-console]
  gem "web-console"
end

group :test do
  # Use system testing [https://guides.rubyonrails.org/testing.html#system-testing]
  gem "capybara"
  gem "selenium-webdriver"
  gem "shoulda-matchers", "~> 6.5"
  gem "webmock"
  gem "rails-controller-testing"
end

gem "letter_opener", "~> 1.10"

gem "dockerfile-rails", ">= 1.7", group: :development
