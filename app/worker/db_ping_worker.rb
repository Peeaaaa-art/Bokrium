class DbPingWorker
  include Sidekiq::Worker
  sidekiq_options queue: :default

  def perform
    #   ActiveRecord::Base.connection.execute("SELECT 1")
    #   Rails.logger.info "🔁 DbPingWorker: SELECT 1 sent to keep Neon awake"
    # rescue => e
    #   Rails.logger.warn "⚠️ DbPingWorker: Failed to ping Neon: #{e.class} - #{e.message}"
  end
end
