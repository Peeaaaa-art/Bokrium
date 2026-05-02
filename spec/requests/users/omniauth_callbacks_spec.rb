# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Users::OmniauthCallbacks", type: :request do
  around do |example|
    original_test_mode = OmniAuth.config.test_mode
    original_mock_auth = OmniAuth.config.mock_auth[:line]
    OmniAuth.config.test_mode = true

    example.run
  ensure
    OmniAuth.config.test_mode = original_test_mode
    OmniAuth.config.mock_auth[:line] = original_mock_auth
    Rails.application.env_config.delete("omniauth.auth")
  end

  describe "GET /users/auth/line/callback" do
    let(:auth_hash) do
      OmniAuth::AuthHash.new(
        provider: "line",
        uid: "line-user-id",
        info: { name: "LINE User" }
      )
    end

    before do
      OmniAuth.config.mock_auth[:line] = auth_hash
      Rails.application.env_config["omniauth.auth"] = auth_hash
    end

    it "remembers an existing LINE user after sign in" do
      user = create(:user)
      create(:line_user, user: user, line_id: "line-user-id")

      get "/users/auth/line/callback"

      expect(response).to redirect_to(mypage_path)
      expect(user.reload.remember_created_at).to be_present
    end

    it "remembers a newly created LINE user after sign in" do
      get "/users/auth/line/callback"

      user = User.find_by!(auth_provider: "line")
      expect(response).to redirect_to(guest_starter_books_path)
      expect(user.remember_created_at).to be_present
    end
  end
end
