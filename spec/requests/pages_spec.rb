require 'rails_helper'

RSpec.describe "Pages", type: :request do
  describe "GET /index" do
    it "Terms" do
      get "/terms"
      expect(response).to have_http_status(:ok)
    end
    it "Privacy" do
      get "/privacy"
      expect(response).to have_http_status(:ok)
    end
    it "Legal" do
      get "/legal"
      expect(response).to have_http_status(:ok)
    end
    it "FAQ" do
      get "/faq"
      expect(response).to have_http_status(:ok)
    end
  end
end
