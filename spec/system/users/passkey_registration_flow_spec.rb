require 'rails_helper'

# WebAuthn はブラウザの navigator.credentials.create/get API に依存するため、
# システムテストではハードウェア／プラットフォーム認証子をモックしづらい。
# サーバー側の登録・ログイン・リダイレクトは request spec で検証している。
# - spec/requests/users/credentials_spec.rb（パスキー登録）
# - spec/requests/users/webauthn_sessions_spec.rb（パスキーログイン）
# - spec/requests/users/passkey_setup_spec.rb（初期設定画面）
# E2E は手動確認、または Playwright 等で仮想認証子（Virtual Authenticator）を有効にしたうえで実装する。
RSpec.describe "Passkey Registration Flow", type: :system do
  describe "新規ユーザー登録からパスキー設定まで" do
    it "ユーザー登録 → メール確認 → パスキー設定 → ログイン の一連のフローが完了する" do
      skip "WebAuthn API requires browser environment with hardware/platform authenticator"
    end
  end

  describe "既存ユーザーがパスキーを追加" do
    it "マイページからパスキーを追加できる" do
      skip "WebAuthn API requires browser environment with hardware/platform authenticator"
    end
  end
end
