require "sidekiq"
require "sidekiq-unique-jobs"

Sidekiq.configure_server do |config|
  config.redis = { url: ENV["REDIS_URL"], ssl: true } if ENV["REDIS_URL"].present?

  SidekiqUniqueJobs.configure do |uniq_config|
    uniq_config.enabled = true
  end
end

Sidekiq.configure_client do |config|
  config.redis = { url: ENV["REDIS_URL"], ssl: true } if ENV["REDIS_URL"].present?
end
