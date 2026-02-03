# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Users::PasskeySetup (パスキー初期設定画面)", type: :request do
  let(:user) { create(:user, password: "password123", confirmed_at: Time.current) }

  before do
    post user_session_path, params: {
      user: { email: user.email, password: "password123" }
    }
  end

  describe "GET /users/passkey_setup" do
    context "パスキー未登録のとき" do
      it "200 を返す" do
        get setup_passkey_path
        expect(response).to have_http_status(:ok)
      end
    end

    context "パスキー既登録のとき" do
      before { create(:credential, user: user) }

      it "302 でマイページへリダイレクトする" do
        get setup_passkey_path
        expect(response).to have_http_status(:found)
        expect(response).to redirect_to(mypage_path)
        expect(flash[:notice]).to eq("パスキーは既に登録されています。")
      end
    end
  end

  describe "POST /users/passkey_setup/complete" do
    it "302 でスターターガイドへリダイレクトする" do
      post complete_passkey_setup_path
      expect(response).to have_http_status(:found)
      expect(response).to redirect_to(guest_starter_books_path)
      expect(flash[:notice]).to eq("パスキーの設定が完了しました！")
    end
  end

  describe "POST /users/passkey_setup/skip" do
    it "302 でスターターガイドへリダイレクトする" do
      post skip_passkey_setup_path
      expect(response).to have_http_status(:found)
      expect(response).to redirect_to(guest_starter_books_path)
      expect(flash[:notice]).to include("スキップ")
    end
  end
end
