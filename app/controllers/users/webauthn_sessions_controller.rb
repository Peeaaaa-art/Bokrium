# frozen_string_literal: true

module Users
  class WebauthnSessionsController < ApplicationController
    # ログイン開始（challenge 生成）
    def new
      # WebAuthn の認証オプションを生成
      options = WebAuthn::Credential.options_for_get(
        allow: [],
        user_verification: "preferred"
      )

      # challenge を URLsafe Base64 (padding なし) でエンコードしてセッションに保存
      challenge_b64 = Base64.urlsafe_encode64(options.challenge, padding: false)
      session[:webauthn_challenge] = challenge_b64

      # フロントエンドに JSON で返す（同じ形式で）
      render json: {
        challenge: challenge_b64,
        timeout: options.timeout,
        rpId: WebAuthn.configuration.rp_id,
        allowCredentials: [],
        userVerification: "preferred"
      }
    end

    # ログイン完了（署名検証）
    def create
      webauthn_credential = WebAuthn::Credential.from_get(params)

      # セッションから challenge を取得
      stored_challenge = session[:webauthn_challenge]

      # challenge が存在しない場合
      unless stored_challenge
        render json: { error: "認証セッションが無効です。再度お試しください。" }, status: :bad_request
        return
      end

      # credential を DB から検索
      credential = Credential.find_by(external_id: Base64.strict_encode64(webauthn_credential.raw_id))

      unless credential
        render json: { error: "このパスキーは登録されていません。" }, status: :not_found
        return
      end

      # 署名を検証
      # verify() は内部で encoder.decode(challenge) を呼ぶので、
      # challenge は base64 エンコードされた文字列を渡す必要がある
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

      # sign_count を更新（replay attack 対策）
      credential.update!(sign_count: webauthn_credential.sign_count)

      # セッションから challenge を削除
      session.delete(:webauthn_challenge)

      # ユーザーをログイン
      user = credential.user
      sign_in(user)

      # レスポンス
      render json: { success: true, redirect_to: after_sign_in_path_for(user) }
    end

    private

    def after_sign_in_path_for(resource)
      stored_location_for(resource) || mypage_path
    end
  end
end
