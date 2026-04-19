# frozen_string_literal: true

module Users
  class CredentialsController < ApplicationController
    before_action :authenticate_user!

    # 登録開始（challenge 生成）
    def new
      options = WebAuthn::Credential.options_for_create(
        user: {
          id: current_user.id.to_s,
          name: current_user.email,
          display_name: current_user.name || current_user.email
        },
        exclude: current_user.credentials.pluck(:external_id),
        authenticator_selection: {
          # authenticator_attachment を指定しない（platform と cross-platform 両方を許可）
          require_resident_key: false,
          user_verification: "preferred"
        }
      )

      session[:webauthn_creation_challenge] = options.challenge

      render json: options
    end

    # 登録完了（credential 保存）
    def create
      stored_challenge = session[:webauthn_creation_challenge]

      unless stored_challenge
        render json: { error: "登録セッションが無効です。再度お試しください。" }, status: :bad_request
        return
      end

      webauthn_credential = WebAuthn::Credential.from_create(params)

      begin
        webauthn_credential.verify(stored_challenge)
      rescue WebAuthn::Error => e
        Rails.logger.error("WebAuthn 登録失敗: #{e.class} - #{e.message}")
        render json: { error: "登録に失敗しました。再度お試しください。" }, status: :unprocessable_entity
        return
      end

      # credential を保存
      credential = current_user.credentials.build(
        external_id: Base64.strict_encode64(webauthn_credential.raw_id),
        public_key: webauthn_credential.public_key,
        sign_count: webauthn_credential.sign_count
      )

      if credential.save
        session.delete(:webauthn_creation_challenge)

        # パスキー登録完了後、スターターガイドへリダイレクト
        render json: {
          success: true,
          message: "パスキーを登録しました。",
          redirect_to: guest_starter_books_path
        }
      else
        render json: { error: credential.errors.full_messages.join(", ") }, status: :unprocessable_entity
      end
    end

    # 削除
    def destroy
      credential = current_user.credentials.find(params[:id])
      credential.destroy!

      redirect_to mypage_path, notice: "パスキーを削除しました。"
    rescue ActiveRecord::RecordNotFound
      redirect_to mypage_path, alert: "パスキーが見つかりませんでした。"
    end
  end
end
