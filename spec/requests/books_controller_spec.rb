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
      expect(response).to redirect_to(books_path)
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
      post books_path, params: {
        book: { title: "", isbn: "" }
      }
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
      expect(response.body).to include("削除しました")
    end
    end
  describe "POST /books/:id/toggle_tag" do
    before { sign_in user }

    it "タグ切り替えサービスが呼び出され、元のページにリダイレクトされること" do
      expect(BookTagToggleService).to receive(:new).and_call_original
      post toggle_tag_book_path(book), params: { tag_id: user_tag.id }
      expect(response).to redirect_to(book_path(book))
    end
  end

  describe "GET /books/tag_filter" do
    before { sign_in user }

    it "タグフィルターパーシャルが描画されること" do
      get tag_filter_books_path, headers: { 'Turbo-Frame' => 'filter' }
      expect(response).to render_template(partial: "_tag_filter")
    end
  end
end
