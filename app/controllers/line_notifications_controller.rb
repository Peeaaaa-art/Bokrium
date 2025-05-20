class LineNotificationsController < ApplicationController
  skip_before_action :verify_authenticity_token, only: :trigger

  before_action :authenticate_user!, only: :toggle

  def toggle
    enabled = ActiveModel::Type::Boolean.new.cast(params.dig(:line_user, :notifications_enabled))
    current_user.line_user.update!(notifications_enabled: enabled)
    redirect_to mypage_path(current_user), notice: "通知設定を更新しました"
  end

  def trigger
    provided_token = request.headers["X-Trigger-Token"]
    unless ActiveSupport::SecurityUtils.secure_compare(provided_token.to_s, ENV["LINE_TRIGGER_TOKEN"].to_s)
      head :unauthorized and return
    end

    LineNotificationSender.send_all
    head :ok
  end
end
