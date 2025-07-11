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
