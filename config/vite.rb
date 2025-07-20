ViteRuby.configure do |config|
  if Rails.env.production?
    config.asset_host = "https://assets.bokrium.com"
  end
end
