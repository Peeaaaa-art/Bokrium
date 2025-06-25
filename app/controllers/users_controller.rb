class UsersController < ApplicationController
  before_action :authenticate_user!
  def show
    @user = current_user
  end

  def toggle_email_notifications
    current_user.update(email_notification_enabled: !current_user.email_notification_enabled)
    redirect_back fallback_location: root_path, notice: "メール通知の設定を変更しました。"
  end
end
