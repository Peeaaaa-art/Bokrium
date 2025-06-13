class WelcomeController < ApplicationController
  def index
    if user_signed_in?
      memos = current_user.memos.includes(:book)
      @random_memo = memos.random_1
      @memo_exists = memos.exists?
    end

    if params[:session_id].present?
      flash.now[:notice] = "Bokrium+にご登録いただき、ありがとうございます！"
      # 将来的にはここで session_id を使ってStripeから情報取得もできる
    elsif params[:canceled]
      flash.now[:alert] = "決済はキャンセルされました。"
    end
  end
end
