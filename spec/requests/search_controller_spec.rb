require 'rails_helper'

RSpec.describe "SearchController", type: :request do
  describe "GET /search (ISBN検索)" do
    before do
      allow(BookApis::RakutenService).to receive(:fetch).and_return(nil)
      allow(BookApis::GoogleBooksService).to receive(:fetch).and_return(nil)
      allow(BookApis::OpenBdService).to receive(:fetch).and_return(nil)
      allow(BookApis::NdlService).to receive(:fetch).and_return(nil)
    end

    it "不正なISBNのとき警告メッセージを返す" do
      get search_books_path(type: "isbn", query: "12345")
      expect(response.body).to include("12345")
      expect(response.body).to include("12345 は有効なISBNではありません")
    end

    it "APIで書籍が見つからないとき警告を出す" do
      get search_books_path(type: "isbn", query: "9781234567897")
      expect(response.body).to include("該当する書籍が見つかりませんでした")
    end
  end

  describe "GET /search (typeが不正 or 空クエリ)" do
    it "typeが無効なとき何も検索されない" do
      get search_books_path(type: "unknown", query: "foo")
      expect(response.body).not_to include("book-card")
    end

    it "queryが空のとき何も検索されない" do
      get search_books_path(type: "title", query: "")
      expect(response.body).not_to include("book-card")
    end
  end

  describe "GET /search (楽天エンジン時)" do
    before do
      allow(BookApis::RakutenService).to receive(:search_by_title_or_author).and_return({
        items: [],
        total_count: 0
      })
    end

    it "楽天ブックスで結果がないとき警告を表示する" do
      get search_books_path(type: "title", query: "存在しない本", engine: "rakuten")
      expect(response.body).to include("楽天ブックスで該当する書籍が見つかりませんでした")
    end

    it "楽天ブックスで検索成功時に結果を描画する" do
      allow(BookApis::RakutenService).to receive(:search_by_title_or_author).and_return({
        items: [
          {
            title: "架空の書籍",
            author: "テスト著者",
            publisher: "テスト出版社",
            isbn: "9781234567890",
            price: 1400,
            book_cover: "http://example.com/cover.jpg",
            affiliate_url: "https://books.rakuten.co.jp/rb/12345678/"
          }
        ],
        total_count: 1
      })

      get search_books_path(type: "title", query: "架空の書籍", engine: "rakuten")
      expect(response.body).to include("架空の書籍")
      expect(response.body).to include("テスト著者")
    end
  end

  describe "GET /search (Googleエンジン時)" do
    it "engine=googleならGoogle検索にリダイレクトする" do
      get search_books_path(type: "title", query: "Ruby", engine: "google")
      expect(response).to redirect_to(search_google_books_path(query: "Ruby", page: 1))
    end
  end

  describe "GET /search_google_books" do
    it "クエリが空ならトップへリダイレクトする" do
      get search_google_books_path(query: "")
      expect(response).to redirect_to(search_books_path)
    end

    it "クエリがあり結果が空なら警告を表示する" do
      allow(BookApis::GoogleBooksService).to receive(:fetch_by_title_or_author).and_return({ items: [], total_count: 0 })

      get search_google_books_path(query: "Ruby", page: 1)
      expect(response.body).to include("Google Booksで該当する書籍が見つかりませんでした")
    end
  end
end
