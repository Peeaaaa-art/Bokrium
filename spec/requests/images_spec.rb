require 'rails_helper'

RSpec.describe "Images", type: :request do
  let(:user) { FactoryBot.create(:user) }
  let(:book) { FactoryBot.create(:book, user: user) }

  describe "未ログイン時" do
    it "POST /books/:book_id/images はサインインへリダイレクトする" do
      post book_images_path(book), params: { image: { image_s3: "dummy" } }
      expect(response).to redirect_to(new_user_session_path)
    end

    it "DELETE /books/:book_id/images/:id はサインインへリダイレクトする" do
      image = FactoryBot.create(:image, book: book)
      delete book_image_path(book, image)
      expect(response).to redirect_to(new_user_session_path)
    end
  end

  describe "ログイン時" do
    before { sign_in user }

    it "画像を作成できる" do
      expect {
        post book_images_path(book), params: {
          image: { image_s3: fixture_file_upload("sample.png", "image/png") }
        }
      }.to change(Image, :count).by(1)
      expect(response).to redirect_to(book_path(book))
    end
  end
end
