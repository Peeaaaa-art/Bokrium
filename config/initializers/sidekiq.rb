require "sidekiq"
require "sidekiq-unique-jobs"
require "sidekiq-cron"

redis_url = ENV["REDIS_URL"] || "redis://localhost:6379"

Sidekiq.configure_server do |config|
  config.redis = { url: redis_url }

  SidekiqUniqueJobs.configure do |uniq_config|
    uniq_config.enabled = true
  end

  # schedule_file = Rails.root.join("config/sidekiq.yml")
  # if File.exist?(schedule_file)
  #   schedule_data = YAML.load_file(schedule_file).deep_symbolize_keys
  #   Sidekiq::Cron::Job.load_from_hash(schedule_data[:schedule]) if schedule_data[:schedule]
  # end
end

Sidekiq.configure_client do |config|
  config.redis = { url: redis_url }
end
