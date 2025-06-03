class LineUsersController < ApplicationController
  before_action :authenticate_user!

  def destroy
    if current_user.line_login_only?
      redirect_to mypage_path(current_user), alert: "LINEのみで登録されたアカウントでは、LINE連携を解除できません。"
      return
    end

    current_user.line_user.destroy!
    redirect_to mypage_path(current_user), notice: "LINE連携を解除しました。"
  end
end
