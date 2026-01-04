# frozen_string_literal: true

module Users
  class CredentialsController < ApplicationController
    before_action :authenticate_user!

    # 登録開始（challenge 生成）
    def new
      # WebAuthn の登録オプションを生成
      options = WebAuthn::Credential.options_for_create(
        user: {
          id: current_user.id.to_s,
          name: current_user.email,
          display_name: current_user.name || current_user.email
        },
        exclude: current_user.credentials.pluck(:external_id).map { |id| Base64.strict_decode64(id) },
        authenticator_selection: {
          authenticator_attachment: "platform",  # Touch ID / Face ID を優先
          require_resident_key: false,
          user_verification: "preferred"
        }
      )

      # challenge をセッションに保存（URLセーフBase64、パディングなしで保存）
      challenge_b64 = Base64.urlsafe_encode64(options.challenge, padding: false)
      session[:webauthn_challenge] = challenge_b64

      # フロントエンドに JSON で返す
      render json: {
        challenge: challenge_b64,
        rp: {
          name: options.rp.name,
          id: options.rp.id
        },
        user: {
          id: Base64.strict_encode64(options.user.id),
          name: options.user.name,
          displayName: options.user.display_name
        },
        pubKeyCredParams: options.pub_key_cred_params,
        timeout: options.timeout,
        excludeCredentials: options.exclude.map { |cred|
          {
            type: cred.type,
            id: Base64.strict_encode64(cred.id)
          }
        },
        authenticatorSelection: options.authenticator_selection,
        attestation: options.attestation
      }
    end

    # 登録完了（credential 保存）
    def create
      # セッションから challenge を取得
      stored_challenge_b64 = session[:webauthn_challenge]

      unless stored_challenge_b64
        render json: { error: "登録セッションが無効です。再度お試しください。" }, status: :bad_request
        return
      end

      # URLセーフBase64デコードしてバイナリに戻す
      stored_challenge = Base64.urlsafe_decode64(stored_challenge_b64)

      # デバッグログ
      Rails.logger.debug("=== WebAuthn verification ===")
      Rails.logger.debug("Stored challenge (hex): #{stored_challenge.unpack1('H*')}")
      Rails.logger.debug("Stored challenge (base64): #{stored_challenge_b64}")
      Rails.logger.debug("Stored challenge class: #{stored_challenge.class}")
      Rails.logger.debug("Stored challenge encoding: #{stored_challenge.encoding}")

      # WebAuthn検証（webauthn gemがclientDataJSONから challengeを抽出して検証）
      webauthn_credential = WebAuthn::Credential.from_create(params)

      # clientDataJSON から challenge を取得して比較
      client_data_json_binary = Base64.urlsafe_decode64(params[:response][:clientDataJSON])
      client_data_hash = JSON.parse(client_data_json_binary)
      client_challenge_b64 = client_data_hash['challenge']
      client_challenge_binary = Base64.urlsafe_decode64(client_challenge_b64)

      Rails.logger.debug("=== Challenge binary comparison ===")
      Rails.logger.debug("Client challenge (hex): #{client_challenge_binary.unpack1('H*')}")
      Rails.logger.debug("Client challenge class: #{client_challenge_binary.class}")
      Rails.logger.debug("Client challenge encoding: #{client_challenge_binary.encoding}")
      Rails.logger.debug("Binary match?: #{stored_challenge == client_challenge_binary}")
      Rails.logger.debug("Byte-by-byte match?: #{stored_challenge.bytes == client_challenge_binary.bytes}")

      begin
        # 検証実行
        # verify() は内部で encoder.decode(challenge) を呼ぶので、
        # challenge は base64 エンコードされた文字列を渡す必要がある
        webauthn_credential.verify(stored_challenge_b64)
        Rails.logger.debug("WebAuthn verification successful!")
      rescue WebAuthn::ChallengeVerificationError => e
        Rails.logger.error("Challenge verification failed!")
        Rails.logger.error("Error: #{e.inspect}")

        # clientDataJSON をデコードして詳細を確認
        client_data_json = Base64.urlsafe_decode64(params[:response][:clientDataJSON])
        client_data = JSON.parse(client_data_json)
        Rails.logger.error("Client challenge (from clientDataJSON): #{client_data['challenge']}")
        Rails.logger.error("Stored challenge (base64): #{stored_challenge_b64}")
        Rails.logger.error("Match?: #{client_data['challenge'] == stored_challenge_b64}")

        render json: { error: "登録に失敗しました。再度お試しください。" }, status: :unprocessable_entity
        return
      rescue WebAuthn::Error => e
        Rails.logger.error("WebAuthn 登録失敗: #{e.class} - #{e.message}")
        Rails.logger.error("Full error: #{e.inspect}")
        Rails.logger.error("Backtrace: #{e.backtrace.first(10).join("\n")}")
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
        # セッションから challenge を削除
        session.delete(:webauthn_challenge)

        render json: { success: true, message: "パスキーを登録しました。" }
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
