require 'rails_helper'

RSpec.describe "Memos", type: :request do
  let(:user) { FactoryBot.create(:user) }
  let(:book) { FactoryBot.create(:book, user: user) }

  before do
    post user_session_path, params: {
      user: { email: user.email, password: user.password }
    }
  end

  describe "POST /books/:book_id/memos" do
    it "メモを作成できる" do
      expect {
        post book_memos_path(book), params: {
          memo: { content: "新しいメモ", visibility: "only_me" }
        }
      }.to change(Memo, :count).by(1)
      expect(response).to redirect_to(book_path(book))
    end

    it "1冊の書籍に複数のメモを作成できる" do
      expect {
        2.times do |i|
          post book_memos_path(book), params: {
            memo: { content: "メモ#{i}", visibility: "only_me" }
          }
        end
      }.to change(Memo, :count).by(2)

      expect(book.memos.count).to eq(2)
    end

    it "root キー :memo が無い場合は 400 Bad Request を返すこと" do
      # params.expect の必須 root キー欠落時の仕様
      post book_memos_path(book), params: {}
      expect(response).to have_http_status(:bad_request)
    end
  end

  describe "PATCH /books/:book_id/memos/:id" do
    let!(:memo) { FactoryBot.create(:memo, book: book, user: user, content: "旧メモ") }

    it "メモを更新できる" do
      patch book_memo_path(book, memo), params: {
        memo: { content: "更新されたメモ", visibility: "public_site" }
      }
      expect(response).to redirect_to(book_path(book))
      expect(memo.reload.content).to eq("更新されたメモ")
    end

    it "root キー :memo が無い場合は 400 Bad Request を返すこと" do
      # params.expect の必須 root キー欠落時の仕様
      patch book_memo_path(book, memo), params: {}
      expect(response).to have_http_status(:bad_request)
    end
  end

  describe "DELETE /books/:book_id/memos/:id" do
    let!(:memo) { FactoryBot.create(:memo, book: book, user: user) }

    it "メモを削除できる" do
      expect {
        delete book_memo_path(book, memo)
      }.to change(Memo, :count).by(-1)
    end
  end
end
