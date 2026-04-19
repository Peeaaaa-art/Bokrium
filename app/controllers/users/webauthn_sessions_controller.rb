# frozen_string_literal: true

module Users
  class WebauthnSessionsController < ApplicationController
    # ログイン開始（challenge 生成）
    def new
      options = WebAuthn::Credential.options_for_get(
        allow: [],
        user_verification: "preferred"
      )

      session[:webauthn_authentication_challenge] = options.challenge

      render json: options
    end

    # ログイン完了（署名検証）
    def create
      webauthn_credential = WebAuthn::Credential.from_get(params)

      stored_challenge = session[:webauthn_authentication_challenge]

      unless stored_challenge
        render json: { error: "認証セッションが無効です。再度お試しください。" }, status: :bad_request
        return
      end

      credential = Credential.find_by(external_id: Base64.strict_encode64(webauthn_credential.raw_id))

      unless credential
        render json: { error: "このパスキーは登録されていません。" }, status: :not_found
        return
      end

      begin
        webauthn_credential.verify(
          stored_challenge,
          public_key: credential.public_key,
          sign_count: credential.sign_count
        )
      rescue WebAuthn::Error => e
        Rails.logger.error("WebAuthn 認証失敗: #{e.class} - #{e.message}")
        render json: { error: "認証に失敗しました。再度お試しください。" }, status: :unauthorized
        return
      end

      credential.update!(sign_count: webauthn_credential.sign_count)

      session.delete(:webauthn_authentication_challenge)

      user = credential.user
      sign_in(user)

      render json: { success: true, redirect_to: after_sign_in_path_for(user) }
    end

    private

    def after_sign_in_path_for(resource)
      stored_location_for(resource) || mypage_path
    end
  end
end
