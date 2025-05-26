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
      get explore_index_path(q: "Ruby", scope: "mine")
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Ruby入門")
    end

    # it "自分のメモを内容で検索できる" do
    #   get explore_index_path(q: "この本は最高", scope: "mine")
    #   expect(response.body).to include("Ruby入門")
    # end

    it "クエリが空でも自分の本一覧が返る" do
      get explore_index_path(scope: "mine")
      expect(response.body).to include("Ruby入門")
    end
  end

  describe "GET /explore with public scope" do
    let(:other_user) { create(:user) }

    before do
      @public_book = create(:book, title: "青空文庫", author: "夏目漱石", user: other_user)
      @public_memo = create(:memo, content: "吾輩は猫である", book: @public_book, user: other_user, visibility: Memo::VISIBILITY[:public_site])
    end

    # it "公開メモの内容で検索できる" do
    #   get explore_index_path(q: "吾輩", scope: "public")
    #   expect(response).to have_http_status(:ok)
    #   expect(response.body).to include("青空")
    # end

    it "公開メモの本のタイトルで検索できる" do
      get explore_index_path(q: "青空文庫", scope: "public")
      expect(response.body).to include("吾輩は猫である") # メモが含まれるか確認
    end

    it "クエリが空でも公開メモ一覧が返る" do
      get explore_index_path(scope: "public")
      expect(response.body).to include("吾輩は猫である")
    end
  end

  describe "Turbo frame request" do
    before do
      sign_in user
      @book = create(:book, title: "Turbo本", user: user)
    end

    it "turbo-frameリクエストに対してTurbo Streamを返す" do
      get explore_index_path(q: "Turbo", scope: "mine"), headers: { "Turbo-Frame" => "books_frame" }
      expect(response.media_type).to eq("text/vnd.turbo-stream.html")
      expect(response.body).to include("Turbo本")
    end
  end
end