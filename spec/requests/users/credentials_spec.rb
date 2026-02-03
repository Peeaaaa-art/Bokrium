# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Users::Credentials (Passkey 登録)", type: :request do
  let(:user) { create(:user, password: "password123", confirmed_at: Time.current) }

  before { sign_in user }

  describe "GET /users/credentials/new" do
    it "登録オプションを JSON で返す（challenge, rp, user, pubKeyCredParams を含む）" do
      get new_user_credential_path, as: :json

      expect(response).to have_http_status(:ok)
      json = response.parsed_body
      expect(json).to include("challenge", "rp", "user", "pubKeyCredParams")
      expect(json["rp"]).to include("name", "id")
      expect(json["user"]).to include("id", "name", "displayName")
    end
  end

  describe "POST /users/credentials" do
    it "WebAuthn をモックしてパスキーを登録し、success と redirect_to を返し Credential が 1 件増える" do
      get new_user_credential_path, as: :json
      expect(response).to have_http_status(:ok)

      challenge = response.parsed_body["challenge"]
      mock = mock_webauthn_credential_create(challenge: challenge)

      expect {
        post user_credentials_path, params: mock[:params], as: :json
      }.to change(Credential, :count).by(1)

      expect(response).to have_http_status(:ok)
      json = response.parsed_body
      expect(json["success"]).to eq(true)
      expect(json).to include("redirect_to")
      expect(json["redirect_to"]).to eq(guest_starter_books_path)
    end
  end
end
