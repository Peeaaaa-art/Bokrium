require 'rails_helper'

RSpec.describe "Books", type: :request do
  let(:user) { create(:user, password: "password123", confirmed_at: Time.current) }

  before do
    post user_session_path, params: {
      user: {
        email: user.email,
        password: "password123"
      }
    }
  end

  describe "GET /books/:id" do
    it "書籍の詳細が表示される" do
      book = create(:book, user: user, title: "詳細テスト本")

      get book_path(book)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("詳細テスト本")
    end
  end

  describe "POST /books" do
    it "書籍を新規登録し、search_books_pathにリダイレクト & フラッシュ表示" do
      long_title = "これは非常に長いタイトルで、40文字以上のものを用意しておきますね。Application_controllerで40を代入しています"
      post books_path, params: {
        book: {
          title: long_title,
          isbn: "9781234567890"
        }
      }

      expect(response).to redirect_to(search_books_path)

      # フラッシュメッセージにリンクが含まれていることを確認
      book = Book.last
      truncated_title = long_title.truncate(ApplicationController::TITLE_TRUNCATE_LIMIT)
      expect(flash[:info]).to include("本棚に")
      expect(flash[:info]).to include("『#{truncated_title}』")
      expect(flash[:info]).to include("を追加しました")
      # リンクが含まれていることを確認
      expect(flash[:info]).to include("<a href=\"/books/#{book.id}\">")
    end
  end

  describe "PATCH /books/:id" do
    it "書籍の情報を更新できる & フラッシュ表示" do
      book = create(:book, user: user, title: "古いタイトル")
      long_title = "新しいタイトルに関する考察を繰り返し述べることで理解を深める試み"

      patch book_path(book), params: {
        book: {
          title: long_title
        }
      }

      expect(response).to redirect_to(book_path(book))
      follow_redirect!
      expect(response.body).to include("新しいタイトル")
      truncated_title = long_title.truncate(ApplicationController::TITLE_TRUNCATE_LIMIT)
      expect(response.body).to include("『#{truncated_title}』を更新しました")
    end
  end

  describe "DELETE /books/:id" do
    it "書籍を削除できる（タイトル確認あり）" do
      create(:book, user: user, title: "残す本")
      long_title = "削除対象の本に関する長めのタイトル（繰り返し確認用）"
      book = create(:book, user: user, title: long_title)

      expect {
        delete book_path(book)
      }.to change(Book, :count).by(-1)

      expect(response).to redirect_to(books_path)
      follow_redirect!

      truncated_title = long_title.truncate(ApplicationController::TITLE_TRUNCATE_LIMIT)
      expect(response.body).to include("『#{truncated_title}』を削除しました")
      expect(response.body).to include("残す本")
    end
  end
end
