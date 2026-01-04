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
      # パスキー登録予定の場合、専用画面へ
      if session[:setup_passkey_after_confirmation]
        session.delete(:setup_passkey_after_confirmation)
        redirect_to setup_passkey_path, notice: "メール確認が完了しました。Bokriumへようこそ！最後にパスキーを設定しましょう。"
      else
        # 通常の初回登録完了 → スターターガイドの後、マイページでパスキー登録を促す
        session[:suggest_passkey_setup] = true
        redirect_to guest_starter_books_path, notice: "メール確認が完了しました。Bokriumへようこそ！"
      end
    end
  end
end
