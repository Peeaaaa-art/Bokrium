class LineUsersController < ApplicationController
  before_action :authenticate_user!

  def destroy
    current_user.line_user&.destroy
    redirect_to mypage_path(current_user), notice: "LINE連携を解除しました。通知も停止されました。"
  end
end
