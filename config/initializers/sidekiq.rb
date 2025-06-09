# config/initializers/sidekiq.rb
if ENV["REDIS_URL"].present?
  Sidekiq.configure_server do |config|
    config.redis = { url: ENV["REDIS_URL"], ssl: true }
  end

  Sidekiq.configure_client do |config|
    config.redis = { url: ENV["REDIS_URL"], ssl: true }
  end
end
