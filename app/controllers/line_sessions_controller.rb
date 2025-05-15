class LineSessionsController < ApplicationController
  def create
    auth = request.env["omniauth.auth"]

    line_id = auth["uid"]
    line_name = auth["info"]["name"]

    # ログイン中のユーザーに line_id を紐づけ
    if current_user
      line_user = LineUser.find_or_initialize_by(user_id: current_user.id)
      line_user.line_id = line_id
      line_user.line_name = line_name
      line_user.save!
      redirect_to user_path(current_user), notice: "LINE連携が完了しました！"
    else
      redirect_to root_path, alert: "ログインが必要です"
    end
  end
end
