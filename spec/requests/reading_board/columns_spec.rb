require "rails_helper"

RSpec.describe "ReadingBoard::Columns", type: :request do
  let(:user) { FactoryBot.create(:user) }
  let(:json_turbo_headers) do
    { "Accept" => "text/vnd.turbo-stream.html", "Content-Type" => "application/json" }
  end

  describe "PATCH /reading_board/column" do
    context "未ログイン" do
      it "ログイン画面へリダイレクトされる" do
        patch reading_board_column_path, params: { status: "reading", ordered_ids: [ 1 ] }
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "ログイン済み" do
      before { sign_in user }

      it "列内の並び順を保存し、リロード後も維持される" do
        book_a = FactoryBot.create(:book, user: user, status: :reading, title: "本A")
        book_b = FactoryBot.create(:book, user: user, status: :reading, title: "本B")
        book_c = FactoryBot.create(:book, user: user, status: :reading, title: "本C")

        patch reading_board_column_path,
          params: { status: "reading", ordered_ids: [ book_c.id, book_a.id, book_b.id ] }.to_json,
          headers: json_turbo_headers

        expect(response).to have_http_status(:ok)
        expect([ book_c, book_a, book_b ].map { |b| b.reload.board_position }).to eq([ 0, 1, 2 ])

        get reading_board_path(view: "kanban")
        body = response.body
        expect(body.index("kanban_card_#{book_c.id}")).to be < body.index("kanban_card_#{book_a.id}")
        expect(body.index("kanban_card_#{book_a.id}")).to be < body.index("kanban_card_#{book_b.id}")
      end

      it "列間移動でステータスとドロップ位置を確定し、両列を返す" do
        moved = FactoryBot.create(:book, user: user, status: :want_to_read)
        existing = FactoryBot.create(:book, user: user, status: :reading)

        patch reading_board_column_path,
          params: { status: "reading", ordered_ids: [ moved.id, existing.id ] }.to_json,
          headers: json_turbo_headers

        expect(response).to have_http_status(:ok)
        expect(moved.reload).to have_attributes(status: "reading", board_position: 0)
        expect(moved.started_on).to eq(Date.current) # 読書中への遷移で自動記録
        expect(existing.reload.board_position).to eq(1)
        expect(response.body).to include("kanban_column_want_to_read", "kanban_column_reading")
      end

      it "不正なステータスは422で何も変更しない" do
        book = FactoryBot.create(:book, user: user, status: :reading)

        patch reading_board_column_path,
          params: { status: "abandoned", ordered_ids: [ book.id ] }.to_json,
          headers: json_turbo_headers

        expect(response).to have_http_status(:unprocessable_content)
        expect(book.reload.board_position).to be_nil
      end

      it "ordered_ids が空なら422" do
        patch reading_board_column_path,
          params: { status: "reading", ordered_ids: [] }.to_json,
          headers: json_turbo_headers

        expect(response).to have_http_status(:unprocessable_content)
      end

      it "他ユーザーの本が混ざっていたら404で何も変更しない" do
        mine = FactoryBot.create(:book, user: user, status: :reading)
        others = FactoryBot.create(:book, user: FactoryBot.create(:user), status: :reading)

        patch reading_board_column_path,
          params: { status: "reading", ordered_ids: [ others.id, mine.id ] }.to_json,
          headers: json_turbo_headers

        expect(response).to have_http_status(:not_found)
        expect(others.reload.board_position).to be_nil
        expect(mine.reload.board_position).to be_nil
      end
    end
  end
end
