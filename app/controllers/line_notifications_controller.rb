class LineNotificationsController < ApplicationController
  before_action :authenticate_user!

  def toggle
    current_user.line_user.update!(notifications_enabled: params[:line_user][:notifications_enabled])
    redirect_to user_path(current_user), notice: "通知設定を更新しました"
  end
end
