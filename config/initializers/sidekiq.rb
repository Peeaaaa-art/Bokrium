Sidekiq.configure_server do |config|
  config.redis = {
    url: ENV.fetch("REDIS_URL"),
    ssl: true,
    reconnect_attempts: 1,
    timeout: 5
  }
end

Sidekiq.configure_client do |config|
  config.redis = {
    url: ENV.fetch("REDIS_URL"),
    ssl: true,
    reconnect_attempts: 1,
    timeout: 5
  }
end
