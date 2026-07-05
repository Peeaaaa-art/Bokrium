require "rails_helper"

RSpec.describe "Books::Statuses", type: :request do
  let(:user) { FactoryBot.create(:user) }
  let(:book) { FactoryBot.create(:book, user: user, status: :want_to_read) }
  let(:turbo_headers) { { "Accept" => "text/vnd.turbo-stream.html" } }

  describe "PATCH /books/:book_id/status" do
    context "未ログイン" do
      it "ログイン画面へリダイレクトされる" do
        patch book_status_path(book), params: { book: { status: "reading" } }
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "ログイン済み" do
      before { sign_in user }

      it "ステータスを変更し、移動元・先の両列をTurbo Streamで返す" do
        patch book_status_path(book), params: { book: { status: "reading" } }, headers: turbo_headers

        expect(response).to have_http_status(:ok)
        expect(response.media_type).to eq("text/vnd.turbo-stream.html")
        expect(book.reload.status).to eq("reading")
        expect(response.body).to include("kanban_column_want_to_read", "kanban_column_reading")
      end

      it "不正なステータスは422で変更されない" do
        patch book_status_path(book), params: { book: { status: "abandoned" } }, headers: turbo_headers

        expect(response).to have_http_status(:unprocessable_content)
        expect(book.reload.status).to eq("want_to_read")
      end

      it "他ユーザーの本は404" do
        others = FactoryBot.create(:book, user: FactoryBot.create(:user))
        patch book_status_path(others), params: { book: { status: "reading" } }, headers: turbo_headers

        expect(response).to have_http_status(:not_found)
      end

      it "HTMLリクエストは読書戦略ボードへリダイレクトする" do
        patch book_status_path(book), params: { book: { status: "finished" } }

        expect(response).to redirect_to(reading_board_path)
        expect(book.reload.status).to eq("finished")
      end
    end
  end
end
