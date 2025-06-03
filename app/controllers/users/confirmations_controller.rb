# frozen_string_literal: true

class Users::ConfirmationsController < Devise::ConfirmationsController
  def show
    # トークンからユーザーを一度取得（confirm前）
    user = resource_class.find_by(confirmation_token: params[:confirmation_token])

    self.resource = resource_class.confirm_by_token(params[:confirmation_token])

    return render :new if resource.errors.present?

    sign_in(resource)

    # トークンによるユーザーが unconfirmed_email を持っていた＝更新による確認
    message =
      if user&.unconfirmed_email.present?
        "メールアドレスを更新しました。"
      else
        "メール確認が完了しました。Bokriumへようこそ！"
      end

    redirect_to root_path, notice: message
  end
end
