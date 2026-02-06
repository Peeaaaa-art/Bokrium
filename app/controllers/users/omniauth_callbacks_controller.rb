# frozen_string_literal: true

# frozen_string_literal: true

class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  def line
    auth = request.env["omniauth.auth"]
    line_id = auth.uid
    line_name = auth.info.name

    # すでにLINE連携済みのユーザー
    if (line_user = LineUser.find_by(line_id: line_id))
      user = line_user.user
      sign_in(user)
      redirect_to mypage_path, notice: "LINEでログインしました。"
      return
    end

    # ログイン中のユーザーがLINE連携を試みた場合
    if user_signed_in? && session.delete(:linking_line_account)
      current_user.create_line_user!(line_id: line_id, line_name: line_name)
      redirect_to mypage_path(current_user), notice: "LINE連携が完了しました。"
      return
    end

    # 新規ユーザーとして作成
    user = User.create!(
      name: line_name || "LINE User",
      email: "line_user_#{SecureRandom.hex(15)}@example.bokrium",
      password: Devise.friendly_token[0, 20],
      confirmed_at: Time.current,
      auth_provider: "line"
    )
    user.create_line_user!(line_id: line_id, line_name: line_name, notifications_enabled: false)

    sign_in(user)

    redirect_to guest_starter_books_path, notice: "LINEアカウントで登録・ログインしました。"
  rescue Regexp::TimeoutError => e
    Rails.logger.warn("Regexp timeout during LINEログイン: #{e.class} - #{e.message}")
    redirect_to new_user_registration_url, alert: I18n.t("users.omniauth.regexp_timeout")
  rescue => e
    Rails.logger.error("LINEログイン失敗: #{e.message}")
    redirect_to new_user_registration_url, alert: "LINEログインに失敗しました。"
  end

  def method_missing(name, *args)
    Rails.logger.info "Called missing method: #{name}"
    super
  end

  def line_connect
    session[:linking_line_account] = true
    redirect_to user_line_omniauth_authorize_path
  end
end
