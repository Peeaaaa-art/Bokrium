# frozen_string_literal: true

WebAuthn.configure do |config|
  # Allowed origins（スキーム + ホスト + ポート）
  # 本番環境では ["https://bokrium.com"] など
  config.allowed_origins = [ ENV.fetch("WEBAUTHN_ORIGIN") { "http://localhost:3000" } ]

  # Relying Party ID（通常はドメイン名）
  # 本番環境では bokrium.com など
  config.rp_id = ENV.fetch("WEBAUTHN_RP_ID") { "localhost" }

  # Relying Party 名（ユーザーに表示される名前）
  config.rp_name = "Bokrium"

  # credential の有効期限（オプション）
  # config.credential_options_timeout = 120_000  # 120秒

  # 認証時のタイムアウト（オプション）
  # config.authentication_timeout = 120_000
end
