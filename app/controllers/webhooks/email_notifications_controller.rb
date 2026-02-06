class Webhooks::EmailNotificationsController < ApplicationController
  skip_before_action :verify_authenticity_token
  before_action :verify_cron_token!

  def create
    EmailNotificationSender.send_all
    render json: { status: "ok", message: "通知を送信しました。" }, status: :ok
  rescue Regexp::TimeoutError => e
    Rails.logger.warn("Regexp timeout in EmailNotifications webhook: #{e.class} - #{e.message}")
    render json: { status: "error", message: "regexp_timeout" }, status: :bad_request
  rescue => e
    Rails.logger.error("メール通知のWebhook失敗: #{e.class} - #{e.message}")
    render json: { status: "error", message: e.message }, status: :internal_server_error
  end

  private

  def verify_cron_token!
    token = request.headers["X-EMAIL-CRON-TOKEN"]
    unless ActiveSupport::SecurityUtils.secure_compare(token.to_s, ENV["EMAIL_CRON_TOKEN"].to_s)
      render json: { status: "unauthorized", message: "無効なトークンです。" }, status: :unauthorized
    end
  end
end
