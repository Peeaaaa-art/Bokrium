class Users::EmailsController < ApplicationController
  before_action :authenticate_user!

  def edit
  end

  def update
    new_email = params[:user][:email]

    if new_email.blank?
      flash.now[:alert] = "メールアドレスを入力してください。"
      render :edit
      return
    end

    current_user.unconfirmed_email = new_email
    if current_user.save
      current_user.send_confirmation_instructions
      redirect_to mypage_path(current_user), notice: "確認メールを送信しました。"
    else
      flash.now[:alert] = "メールアドレスの変更に失敗しました。"
      render :edit
    end
  end
end
