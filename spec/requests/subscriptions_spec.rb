require 'rails_helper'

RSpec.describe "Subscriptions", type: :request do
  describe "POST /subscriptions" do
    it "未ログイン時はサインインへリダイレクトする(Stripeには到達しない)" do
      post create_subscription_path
      expect(response).to redirect_to(new_user_session_path)
    end
  end

  describe "GET /subscriptions/create" do
    it "副作用のある旧GETルートは廃止されている" do
      get "/subscriptions/create"
      expect(response).to have_http_status(:not_found)
    end
  end
end
