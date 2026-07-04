require 'rails_helper'
require 'csv'

RSpec.describe "Exports", type: :request do
  let(:user) { create(:user, password: "password123", confirmed_at: Time.current) }

  before do
    post user_session_path, params: {
      user: {
        email: user.email,
        password: "password123"
      }
    }
  end

  describe "GET /export/books" do
    it "CSVとしてダウンロードされ、ヘッダーが正しい" do
      get export_books_path

      expect(response).to have_http_status(:ok)
      expect(response.headers["Content-Type"]).to include("text/csv")

      rows = CSV.parse(response.body, headers: true)
      expect(rows.headers).to eq(%w[title author isbn publisher page price status tags memos])
    end

    it "自分の書籍のみが含まれ、他ユーザーの書籍は含まれない" do
      book = create(:book, user: user, title: "自分の本")
      other_user = create(:user, password: "password123", confirmed_at: Time.current)
      create(:book, user: other_user, title: "他人の本")

      get export_books_path

      rows = CSV.parse(response.body, headers: true)
      titles = rows.map { |row| row["title"] }

      expect(titles).to include("自分の本")
      expect(titles).not_to include("他人の本")
    end

    it "複数のメモが作成日時順に区切り文字で連結される" do
      book = create(:book, user: user, title: "メモ複数の本")
      create(:memo, user: user, book: book, content: "1つ目のメモ", created_at: 2.days.ago)
      create(:memo, user: user, book: book, content: "2つ目のメモ", created_at: 1.day.ago)

      get export_books_path

      rows = CSV.parse(response.body, headers: true)
      row = rows.find { |r| r["title"] == "メモ複数の本" }

      expect(row["memos"]).to eq("1つ目のメモ\n---\n2つ目のメモ")
    end

    it "メモが0件の本も1行として出力される" do
      create(:book, user: user, title: "メモなしの本")

      get export_books_path

      rows = CSV.parse(response.body, headers: true)
      row = rows.find { |r| r["title"] == "メモなしの本" }

      expect(row).to be_present
      expect(row["memos"]).to eq("")
    end

    it "タグがカンマ区切りで含まれる" do
      book = create(:book, user: user, title: "タグ付きの本")
      tag_a = create(:user_tag, user: user, name: "小説")
      tag_b = create(:user_tag, user: user, name: "お気に入り")
      create(:book_tag_assignment, user: user, book: book, user_tag: tag_a)
      create(:book_tag_assignment, user: user, book: book, user_tag: tag_b)

      get export_books_path

      rows = CSV.parse(response.body, headers: true)
      row = rows.find { |r| r["title"] == "タグ付きの本" }

      expect(row["tags"]).to eq("小説,お気に入り")
    end

    it "未ログインの場合はログインページへリダイレクトされる" do
      delete destroy_user_session_path

      get export_books_path

      expect(response).to redirect_to(new_user_session_path)
    end
  end
end
