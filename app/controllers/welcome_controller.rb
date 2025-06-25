class WelcomeController < ApplicationController
  def index
    if user_signed_in?
      memos = current_user.memos.includes(:book)
      @random_memo = memos.random_1
      @memo_exists = memos.exists?
    end

    if params[:session_id].present?
      flash[:notice] = "Bokriumマンスリーサポートにご参加いただき、ありがとうございます。今後の運営の励みとなります。"
      redirect_to donations_thank_you_path and return
      # 将来的にはここで session_id を使ってStripeから情報取得もできる
    elsif params[:canceled]
      flash.now[:alert] = "ご登録はキャンセルされましたが、Bokriumにご関心をお寄せいただき、ありがとうございました。"
    end

    if params[:donation] == "success"
      flash[:notice] = "ご支援いただき、誠にありがとうございます！"
        session[:recent_donation] = true
        redirect_to donations_thank_you_path and return
    elsif params[:donation] == "cancelled"
      flash.now[:alert] = "寄付はキャンセルされました。"
    end
  end
end
