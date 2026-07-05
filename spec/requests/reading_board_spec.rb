require 'rails_helper'

RSpec.describe "ReadingBoard", type: :request do
  let(:user) { FactoryBot.create(:user) }
  let(:other_user) { FactoryBot.create(:user) }

  describe "未ログイン" do
    it "ボード表示はログイン画面へリダイレクトされる" do
      get reading_board_path
      expect(response).to redirect_to(new_user_session_path)
    end
  end

  describe "ログイン済み" do
    before do
      post user_session_path, params: { user: { email: user.email, password: user.password } }
    end

    describe "GET /reading_board" do
      it "自分の読書中の本だけを表示する" do
        reading = FactoryBot.create(:book, user: user, status: :reading, title: "読書中の本")
        FactoryBot.create(:book, user: user, status: :want_to_read, title: "読みたい本")
        FactoryBot.create(:book, user: other_user, status: :reading, title: "他人の読書中")

        get reading_board_path

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("読書中の本")
        expect(response.body).not_to include("読みたい本")
        expect(response.body).not_to include("他人の読書中")
      end

      it "目標日の近い順(未設定は末尾)に並ぶ" do
        FactoryBot.create(:book, user: user, status: :reading, title: "目標日なし", target_finish_on: nil)
        FactoryBot.create(:book, user: user, status: :reading, title: "遠い目標", target_finish_on: Date.current + 30)
        FactoryBot.create(:book, user: user, status: :reading, title: "近い目標", target_finish_on: Date.current + 3)

        get reading_board_path

        near = response.body.index("近い目標")
        far = response.body.index("遠い目標")
        none = response.body.index("目標日なし")
        expect(near).to be < far
        expect(far).to be < none
      end
    end

    describe "GET /reading_board (かんばんview)" do
      it "ステータス3列が自分の本だけで表示される" do
        FactoryBot.create(:book, user: user, status: :want_to_read, title: "積んでる本")
        FactoryBot.create(:book, user: user, status: :reading, title: "読んでる本")
        FactoryBot.create(:book, user: user, status: :finished, title: "読み終えた本")
        FactoryBot.create(:book, user: other_user, status: :reading, title: "他人の本")

        get reading_board_path(view: "kanban")

        expect(response).to have_http_status(:ok)
        %w[want_to_read reading finished].each do |status|
          expect(response.body).to include("kanban_column_#{status}")
        end
        expect(response.body).to include("積んでる本", "読んでる本", "読み終えた本")
        expect(response.body).not_to include("他人の本")
      end

      it "選択したviewがセッションに記憶される" do
        get reading_board_path(view: "kanban")
        get reading_board_path

        expect(response.body).to include("kanban_column_reading")
      end

      it "不正なviewはリスト表示にフォールバックする" do
        get reading_board_path(view: "bogus")

        expect(response).to have_http_status(:ok)
        expect(response.body).not_to include("kanban_column_reading")
      end

      it "読了列は表示上限を超えない(ヘッダーには総数)" do
        stub_const("ReadingBoardColumns::KANBAN_FINISHED_LIMIT", 2)
        3.times { |i| FactoryBot.create(:book, user: user, status: :finished, title: "読了本#{i}") }

        get reading_board_path(view: "kanban")

        expect(response.body.scan(/kanban_card_\d+/).uniq.size).to eq(2)
        expect(response.body).to include("直近2冊を表示") # 切り詰め時はバッジに総数+説明title
      end
    end

    describe "PATCH /books/:book_id/reading_schedule" do
      let(:book) { FactoryBot.create(:book, user: user, status: :reading, page: 200) }

      it "目標日と現在ページを更新できる" do
        patch book_reading_schedule_path(book), params: {
          book: { target_finish_on: "2026-08-01", current_page: 80 }
        }, headers: { "Accept" => "text/vnd.turbo-stream.html" }

        expect(response).to have_http_status(:ok)
        book.reload
        expect(book.target_finish_on).to eq(Date.new(2026, 8, 1))
        expect(book.current_page).to eq(80)
      end

      it "現在ページが不正なら 422 を返す" do
        patch book_reading_schedule_path(book), params: {
          book: { current_page: -5 }
        }, headers: { "Accept" => "text/vnd.turbo-stream.html" }

        expect(response).to have_http_status(:unprocessable_entity)
        expect(book.reload.current_page).to be_nil
      end

      it "他ユーザーの本は更新できない(404)" do
        others = FactoryBot.create(:book, user: other_user, status: :reading)
        patch book_reading_schedule_path(others), params: { book: { current_page: 10 } }
        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
