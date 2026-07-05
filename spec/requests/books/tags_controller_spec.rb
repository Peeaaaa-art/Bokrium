# spec/requests/books/tags_controller_spec.rb
require "rails_helper"

RSpec.describe "Books::TagsController", type: :request do
  include Rails.application.routes.url_helpers

  let(:user)     { create(:user) }
  let(:book)     { create(:book, user: user) }
  let(:user_tag) { create(:user_tag, user: user) }

  before { sign_in user }

  describe "POST /books/:book_id/tags/toggle" do
    it "タグをトグルして元のページにリダイレクトされること" do
      post toggle_book_tags_path(book_id: book.id), params: { tag_id: user_tag.id }
      expect(response).to redirect_to(book_path(book))
    end

    context "Turbo Stream リクエスト" do
      let(:turbo_headers) { { "Accept" => "text/vnd.turbo-stream.html" } }

      it "リダイレクトせず Turbo Stream で応答すること" do
        post toggle_book_tags_path(book_id: book.id), params: { tag_id: user_tag.id }, headers: turbo_headers
        expect(response).to have_http_status(:ok)
        expect(response.media_type).to eq("text/vnd.turbo-stream.html")
        expect(response.body).to include("book_#{book.id}_tag_#{user_tag.id}")
        expect(response.body).to include("book_tag_badges_#{book.id}")
      end

      it "未付与のタグを付与できること" do
        expect {
          post toggle_book_tags_path(book_id: book.id), params: { tag_id: user_tag.id }, headers: turbo_headers
        }.to change { book.reload.user_tags.count }.by(1)
        expect(response.body).to include(user_tag.name)
      end

      it "付与済みのタグを解除できること" do
        create(:book_tag_assignment, book: book, user_tag: user_tag, user: user)
        expect {
          post toggle_book_tags_path(book_id: book.id), params: { tag_id: user_tag.id }, headers: turbo_headers
        }.to change { book.reload.user_tags.count }.by(-1)
      end

      it "他ユーザーの本には付与できないこと(404)" do
        others_book = create(:book, user: create(:user))
        post toggle_book_tags_path(book_id: others_book.id), params: { tag_id: user_tag.id }, headers: turbo_headers
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "GET /books/filters/filter" do
    it "タグフィルターパーシャルが描画されること" do
      get filter_books_tags_path, headers: { "Turbo-Frame" => "filter" }
      expect(response).to have_http_status(:ok)
      # Turbo Frame の存在で正しく描画されたことを確認
      expect(response.body).to include('id="tag_filter_frame"')
    end
  end
end
