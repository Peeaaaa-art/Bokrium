# spec/requests/books_controller_spec.rb
require 'rails_helper'

RSpec.describe "BooksController", type: :request do
  let(:user) { create(:user) }
  let(:book) { create(:book, user: user) }
  let!(:user_tag) { create(:user_tag, user: user, name: "Ruby") }


  before { ensure_guest_user }

  describe "GET /books" do
    context "when not signed in" do
      it "サインインページにリダイレクトされること" do
        get books_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when signed in" do
      before do
        sign_in user
        create(:book, user: user)
      end

      it "本棚ページが表示されること" do
        get books_path
        expect(response).to have_http_status(:ok)
        expect(response.body).to include("本棚")
        expect(response.body).to include("サンプルタイトル")
      end
    end

    context "when signed in but empty shelf" do
      before { sign_in user }

      it "サンプル本棚ページが表示されること" do
        get guest_books_path
        expect(response).to have_http_status(:ok)
        expect(response.body).to include("サンプル本棚")
        expect(response.body).to include("こちらはサンプル表示です")
        expect(response.body).to include("スターター本")
      end
    end
  end

  describe "GET /books/:id" do
    before { sign_in user }

    it "対象の本が表示されること" do
      get book_path(book)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include(book.title)
    end

    it "存在しないIDを指定した場合は本棚一覧にリダイレクトされること" do
      get book_path(id: 99999)
      expect(response.body).to include("404: Not Found")
    end
  end

  describe "POST /books" do
    before { sign_in user }

    it "正しい情報で本を登録できること" do
      post books_path, params: {
        book: attributes_for(:book, title: "新しい本")
      }
      expect(response).to redirect_to(search_books_path)
      follow_redirect!
      expect(response.body).to include("新しい本")
    end

    it "不正なデータの場合は登録フォームが再表示されること" do
      Bullet.enable = false

      post books_path, params: {
        book: { title: "", isbn: "" }
      }

      Bullet.enable = true

      expect(response.body).to include("Title: タイトルは必須です")
    end
  end

  describe "PATCH /books/:id" do
    before { sign_in user }

    it "本の情報を更新できること" do
      patch book_path(book), params: { book: { title: "更新されたタイトル" } }
      expect(response).to redirect_to(book_path(book))
    end

    it "更新に失敗した場合は編集フォームが再表示されること" do
      patch book_path(book), params: { book: { title: "" } }
      expect(response.body).to include("form")
    end
  end

  describe "DELETE /books/:id" do
    before { sign_in user }

    it "本を削除でき、一覧ページにリダイレクトされること" do
      delete book_path(book)
      expect(response).to redirect_to(books_path)
      follow_redirect!
      expect(flash[:info]).to include("削除しました")
    end
  end
end
