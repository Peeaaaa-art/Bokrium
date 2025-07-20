return unless defined?(ViteRuby)

ViteRuby.configure do |config|
  config.asset_host = "https://assets.bokrium.com" if Rails.env.production?
end