# frozen_string_literal: true

class Users::ConfirmationsController < Devise::ConfirmationsController
  def show
    # トークンからユーザーを一度取得（confirm前）
    user = resource_class.find_by(confirmation_token: params[:confirmation_token])

    self.resource = resource_class.confirm_by_token(params[:confirmation_token])
    return render :new if resource.errors.present?

    sign_in(resource)

    if user&.unconfirmed_email.present?
      redirect_to mypage_path, notice: "メールアドレスを更新しました。"
    else
      redirect_to guest_starter_books_path, notice: "メール確認が完了しました。Bokriumへようこそ！"
    end
  end
end
