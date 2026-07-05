require 'rails_helper'

RSpec.describe "Users::Passwords", type: :request do
  describe "POST /users/password (paranoidモード)" do
    let(:user) { FactoryBot.create(:user) }

    it "存在するメールアドレスでも存在しないメールアドレスでも同じ応答になる(ユーザー列挙対策)" do
      post user_password_path, params: { user: { email: user.email } }
      existing_redirect = response.redirect_url
      existing_flash = flash[:notice]

      post user_password_path, params: { user: { email: "no-such-user@example.com" } }
      expect(response.redirect_url).to eq(existing_redirect)
      expect(flash[:notice]).to eq(existing_flash)
    end

    it "存在しないメールアドレスでもエラーにならずリダイレクトする" do
      post user_password_path, params: { user: { email: "no-such-user@example.com" } }
      expect(response).to have_http_status(:redirect)
    end
  end
end
