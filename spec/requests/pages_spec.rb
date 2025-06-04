require 'rails_helper'

RSpec.describe "Pages", type: :request do
  describe "GET /index" do
    it "正常にレスポンスが返ること" do
      get "/faq"
      expect(response).to have_http_status(:ok)
    end
  end
end
