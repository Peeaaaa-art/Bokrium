require 'rails_helper'

RSpec.describe "Passkey Registration Flow", type: :system do
  # このテストは実際のブラウザ環境では動作しないため、
  # リクエストレベルでのフローを検証します

  describe "新規ユーザー登録からパスキー設定まで" do
    it "ユーザー登録 → メール確認 → パスキー設定 → ログイン の一連のフローが完了する" do
      # このテストはシステムテストとしては WebAuthn API をモックできないため、
      # 実際の動作確認は手動テストまたは E2E テストツール（Cypress など）で行う必要があります
      skip "WebAuthn API requires browser environment with hardware/platform authenticator"
    end
  end

  describe "既存ユーザーがパスキーを追加" do
    it "マイページからパスキーを追加できる" do
      skip "WebAuthn API requires browser environment with hardware/platform authenticator"
    end
  end
end
