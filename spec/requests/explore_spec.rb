require 'rails_helper'

RSpec.describe "Explore", type: :request do
  let(:user) { create(:user) }

  describe "GET /explore with scope=mine" do
    before do
      post user_session_path, params: {
        user: { email: user.email, password: user.password }
      }
      @book = create(:book, title: "Ruby入門", author: "山田", user: user)
      @memo = create(:memo, content: "この本は最高", book: @book, user: user)
    end

    it "自分の本をタイトルで検索できる" do
      get explore_path(q: "Ruby", scope: "mine")
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Ruby入門")
    end

    # it "自分のメモを内容で検索できる" do
    #   get explore_path(q: "この本は最高", scope: "mine")
    #   expect(response.body).to include("Ruby入門")
    # end

    it "クエリが空でも自分の本一覧が返る" do
      get explore_path(scope: "mine")
      expect(response.body).to include("Ruby入門")
    end
  end

  describe "Turbo frame request" do
    let(:user) { create(:user, email: "test@example.com", password: "password123") }

    before do
      post user_session_path, params: {
        user: {
          email: user.email,
          password: "password123"
        }
      }

      @book = create(:book, title: "Turbo本", user: user)
    end

    it "turbo-frameリクエストに対してTurbo Streamを返す" do
      get explore_path(q: "Turbo", scope: "mine"), headers: { "Turbo-Frame" => "books_frame" }
      expect(response.media_type).to eq("text/vnd.turbo-stream.html")
      expect(response.body).to include("Turbo本")
    end
  end
end
