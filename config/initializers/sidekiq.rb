require "sidekiq-unique-jobs"

Sidekiq.configure_server do |config|
  config.redis = { url: ENV["REDIS_URL"], ssl: true } if ENV["REDIS_URL"].present?

  config.server_middleware do |chain|
    chain.add SidekiqUniqueJobs::Server::Middleware
  end

  config.client_middleware do |chain|
    chain.add SidekiqUniqueJobs::Client::Middleware
  end

  SidekiqUniqueJobs::Server.configure(config)
end

Sidekiq.configure_client do |config|
  config.redis = { url: ENV["REDIS_URL"], ssl: true } if ENV["REDIS_URL"].present?

  config.client_middleware do |chain|
    chain.add SidekiqUniqueJobs::Client::Middleware
  end
end
