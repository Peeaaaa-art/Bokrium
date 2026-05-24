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

    it "タイトルの途中一致で自分の本棚を検索できる" do
      matching_book = create(:book, title: "実践Ruby設計", user: user)
      create(:book, title: "Python設計", user: user)

      get explore_path(q: "Ruby", scope: "mine"), headers: { "Turbo-Frame" => "books_frame" }

      expect(response.media_type).to eq("text/vnd.turbo-stream.html")
      expect(response.body).to include(matching_book.title)
      expect(response.body).not_to include("Python設計")
    end

    it "著者の途中一致で自分の本棚を検索できる" do
      matching_book = create(:book, title: "文豪の本", author: "夏目漱石", user: user)
      create(:book, title: "別の本", author: "芥川龍之介", user: user)

      get explore_path(q: "漱石", scope: "mine"), headers: { "Turbo-Frame" => "books_frame" }

      expect(response.media_type).to eq("text/vnd.turbo-stream.html")
      expect(response.body).to include(matching_book.title)
      expect(response.body).not_to include("別の本")
    end

    it "空クエリで自分の本棚一覧を返す" do
      other_book = create(:book, title: "別の本", user: user)

      get explore_path(q: "", scope: "mine"), headers: { "Turbo-Frame" => "books_frame" }

      expect(response.media_type).to eq("text/vnd.turbo-stream.html")
      expect(response.body).to include(@book.title)
      expect(response.body).to include(other_book.title)
    end

    it "サンプル本棚もTurbo Streamで検索できる" do
      guest = ensure_guest_user
      create(:book, title: "ゲストTurbo本", author: "ゲスト著者", user: guest)

      get explore_path(q: "ゲストTurbo", scope: "guest"), headers: { "Turbo-Frame" => "books_frame" }

      expect(response.media_type).to eq("text/vnd.turbo-stream.html")
      expect(response.body).to include("ゲストTurbo本")
    end

    it "検索結果のnext_books URLに検索条件を保持する" do
      create_list(:book, 70, title: "Turbo検索本", user: user)

      get explore_path(q: "Turbo検索", scope: "mine", view: "shelf"), headers: { "Turbo-Frame" => "books_frame" }

      expect(response.body).to include("src=\"/explore?")
      expect(response.body).to include("q=Turbo")
      expect(response.body).to include("scope=mine")
      expect(response.body).to include("view=shelf")
    end

    it "next_booksリクエストで現在の表示モードのchunkを返す" do
      create_list(:book, 70, title: "Turboページ本", user: user)

      %w[shelf spine card detail_card b_note].each do |view_mode|
        get explore_path(q: "Turboページ", scope: "mine", view: view_mode, page: 2), headers: { "Turbo-Frame" => "next_books" }

        expect(response).to have_http_status(:ok)
        expect(response.media_type).to eq("text/html")
        expect(response.body).to include('turbo-frame id="next_books"')
      end
    end
  end
end
