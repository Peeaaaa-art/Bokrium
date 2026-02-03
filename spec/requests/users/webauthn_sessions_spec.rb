# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Users::WebauthnSessions (パスキーログイン)", type: :request do
  let(:user) { create(:user, password: "password123", confirmed_at: Time.current) }
  let!(:credential) { create(:credential, user: user) }

  describe "GET /users/webauthn_login" do
    it "認証オプションを JSON で返す（challenge, rpId, allowCredentials を含む）" do
      get new_user_webauthn_session_path, as: :json

      expect(response).to have_http_status(:ok)
      json = response.parsed_body
      expect(json).to include("challenge", "rpId", "allowCredentials")
    end
  end

  describe "POST /users/webauthn_login" do
    it "WebAuthn をモックしてパスキーでログインし、success と redirect_to を返しサインインする" do
      get new_user_webauthn_session_path, as: :json
      expect(response).to have_http_status(:ok)

      challenge = response.parsed_body["challenge"]
      mock = mock_webauthn_credential_get(credential: credential, challenge: challenge)

      post user_webauthn_session_path, params: mock[:params], as: :json

      expect(response).to have_http_status(:ok)
      json = response.parsed_body
      expect(json["success"]).to eq(true)
      expect(json["redirect_to"]).to eq(mypage_path)

      # サインインしていることを確認（mypage にアクセスして 200 になる）
      get mypage_path
      expect(response).to have_http_status(:ok)
    end
  end
end
