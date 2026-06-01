require 'rails_helper'

RSpec.describe "Pages", type: :request do
  describe "GET /" do
    it "renders the starter guide as the top page" do
      get "/"

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Bokrium")
      expect(response.body).to include("読書の記憶を育てる本棚アプリ")
      expect(response.body).to include('property="og:image" content="https://lib.bokrium.com/bokrium_ogp_meishi.png"')
    end
  end

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
    it "Contact" do
      get "/contact"
      expect(response).to have_http_status(:ok)
    end
    it "FAQ" do
      get "/faq"
      expect(response).to have_http_status(:ok)
    end
  end
end
