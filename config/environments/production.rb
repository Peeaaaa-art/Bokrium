require "active_support/core_ext/integer/time"

Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # Code is not reloaded between requests.
  config.enable_reloading = false

  # Eager load code on boot for better performance and memory savings (ignored by Rake tasks).
  config.eager_load = true

  # Full error reports are disabled.
  config.consider_all_requests_local = false

  # 406 や不意の 500 表示を防ぐため
  config.action_dispatch.block_unknown_browser_requests = false

  # Turn on fragment caching in view templates.
  config.action_controller.perform_caching = true

  # Cache assets for far-future expiry since they are all digest stamped.
  config.public_file_server.headers = { "cache-control" => "public, max-age=#{1.year.to_i}" }

  # Enable serving of images, stylesheets, and JavaScripts from an asset server.
  config.asset_host = "https://assets.bokrium.com"

  # Store uploaded files in Tigris Global Object Storage (see config/storage.yml for options).
  config.active_storage.service = :cloudflare_private_r2

  # Assume all access to the app is happening through a SSL-terminating reverse proxy.
  config.assume_ssl = true

  # Force all access to the app over SSL, use Strict-Transport-Security, and use secure cookies.
  config.force_ssl = true

  # Skip http-to-https redirect for the default health check endpoint.
  # config.ssl_options = { redirect: { exclude: ->(request) { request.path == "/up" } } }

  # Log to STDOUT with the current request id as a default log tag.
  config.log_tags = [ :request_id ]
  config.logger   = ActiveSupport::TaggedLogging.logger(STDOUT)

  # Change to "debug" to log everything (including potentially personally-identifiable information!)
  config.log_level = ENV.fetch("RAILS_LOG_LEVEL", "info")

  # Prevent health checks from clogging up the logs.
  config.silence_healthcheck_path = "/up"

  # Don't log any deprecations.
  config.active_support.report_deprecations = false

  # Replace the default in-process memory cache store with a durable alternative.
  config.cache_store = :solid_cache_store

  # Set host to be used by links generated in mailer templates.
  config.action_mailer.default_url_options = { protocol: "https", host: "bokrium.com" }
  config.action_mailer.delivery_method = :smtp
  config.action_mailer.smtp_settings = {
    address:              "mail.privateemail.com",
    port:                 587,
    domain:               "bokrium.com",
    user_name:            "support@bokrium.com",
    password:             ENV["PRIVATE_EMAIL_PASSWORD"],
    authentication:       "plain",
    enable_starttls_auto: true
  }
  config.action_mailer.raise_delivery_errors = true # 配信失敗したらエラーを出す
  config.action_mailer.perform_caching = false
  # Enable locale fallbacks for I18n (makes lookups for any locale fall back to
  # the I18n.default_locale when a translation cannot be found).
  config.i18n.fallbacks = true

  # Do not dump schema after migrations.
  config.active_record.dump_schema_after_migration = false

  # Only use :id for inspections in production.
  config.active_record.attributes_for_inspect = [ :id ]
  # fly.io対策
  config.hosts.clear

  # リダイレクト: www.bokrium.com → bokrium.com
  config.middleware.insert_before(Rack::Runtime, Rack::Rewrite) do
    r301 %r{.*}, "https://bokrium.com$&", if: Proc.new { |rack_env|
      rack_env["SERVER_NAME"] == "www.bokrium.com"
    }
  end
end

Rails.application.routes.default_url_options = {
  protocol: "https",
  host: "bokrium.com"
}
