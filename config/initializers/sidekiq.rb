require "sidekiq"
require "sidekiq-unique-jobs"

redis_url =
    ENV["REDIS_URL"] || "redis://localhost:6379"

Sidekiq.configure_server do |config|
  config.redis = { url: redis_url }

  SidekiqUniqueJobs.configure do |uniq_config|
    uniq_config.enabled = true
  end
end

Sidekiq.configure_client do |config|
  config.redis = { url: redis_url }
end
