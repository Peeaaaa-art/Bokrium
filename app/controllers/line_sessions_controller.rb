# app/controllers/line_sessions_controller.rb

class LineSessionsController < ApplicationController
  def create
    auth = request.env["omniauth.auth"]

    line_id = auth["uid"]
    line_name = auth["info"]["name"]

    if current_user
      LineUser.find_or_create_by!(user_id: current_user.id) do |line_user|
        line_user.line_id = line_id
        line_user.line_name = line_name
      end

      redirect_to mypage_path(current_user), notice: "LINE連携が完了しました！"
    else
      redirect_to root_path, alert: "ログインしてからLINE連携してください"
    end
  end
end
