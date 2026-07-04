require 'rails_helper'

RSpec.describe "HandwrittenNotes", type: :request do
  let(:user) { FactoryBot.create(:user) }
  let(:book) { FactoryBot.create(:book, user: user) }
  let(:note) { FactoryBot.create(:handwritten_note, user: user, book: book) }
  let(:other_user) { FactoryBot.create(:user) }
  let(:other_book) { FactoryBot.create(:book, user: other_user) }
  let(:other_note) { FactoryBot.create(:handwritten_note, user: other_user, book: other_book) }

  let(:scene_params) do
    {
      handwritten_note: {
        data: {
          type: "excalidraw",
          version: 2,
          elements: [ { id: "abc", type: "freedraw", points: [ [ 0, 0 ], [ 10, 12 ] ] } ],
          appState: { viewBackgroundColor: "#ffffff" }
        }
      }
    }
  end

  describe "未ログイン" do
    it "ログイン画面へリダイレクトされる" do
      get book_handwritten_note_path(book, note)
      expect(response).to redirect_to(new_user_session_path)
    end
  end

  describe "ログイン済み" do
    before do
      post user_session_path, params: {
        user: { email: user.email, password: user.password }
      }
    end

    describe "POST /books/:book_id/handwritten_notes" do
      it "ノートを作成して編集画面へリダイレクトする" do
        expect {
          post book_handwritten_notes_path(book)
        }.to change(HandwrittenNote, :count).by(1)
        created = HandwrittenNote.order(:id).last
        expect(response).to redirect_to(book_handwritten_note_path(book, created))
        expect(created).to have_attributes(user: user, book: book, data: {})
      end

      it "positionは既存の最大+1になる" do
        FactoryBot.create(:handwritten_note, user: user, book: book, position: 3)
        post book_handwritten_notes_path(book)
        expect(HandwrittenNote.order(:id).last.position).to eq(4)
      end

      it "他人の本には作成できない" do
        post book_handwritten_notes_path(other_book)
        expect(response).to have_http_status(:not_found)
      end
    end

    describe "GET /books/:book_id/handwritten_notes/:id" do
      it "編集画面を表示する" do
        get book_handwritten_note_path(book, note)
        expect(response).to have_http_status(:ok)
        expect(response.body).to include("handwritten-note-root")
        expect(response.body).to include(book_handwritten_note_path(book, note))
      end

      it "他人のノートにはアクセスできない" do
        get book_handwritten_note_path(other_book, other_note)
        expect(response).to have_http_status(:not_found)
      end
    end

    describe "PATCH /books/:book_id/handwritten_notes/:id" do
      it "シーンJSONを保存できる" do
        patch book_handwritten_note_path(book, note), params: scene_params, as: :json
        expect(response).to have_http_status(:no_content)

        note.reload
        expect(note.data["elements"].first["type"]).to eq("freedraw")
        expect(note.data["appState"]["viewBackgroundColor"]).to eq("#ffffff")
      end

      it "タイトルだけを保存できる" do
        patch book_handwritten_note_path(book, note),
              params: { handwritten_note: { title: " 第1章の構造 " } }, as: :json
        expect(response).to have_http_status(:no_content)
        expect(note.reload.title).to eq("第1章の構造")
      end

      it "空のタイトルはnilになる" do
        note.update!(title: "既存タイトル")
        patch book_handwritten_note_path(book, note),
              params: { handwritten_note: { title: "" } }, as: :json
        expect(note.reload.title).to be_nil
      end

      it "タイトル保存はdataを変更しない" do
        patch book_handwritten_note_path(book, note), params: scene_params, as: :json
        patch book_handwritten_note_path(book, note),
              params: { handwritten_note: { title: "メモ" } }, as: :json
        expect(note.reload.data["elements"]).to be_present
      end

      it "2MBを超えるdataは保存できない" do
        big_params = { handwritten_note: { data: { elements: [ { text: "a" * 2.megabytes } ] } } }
        patch book_handwritten_note_path(book, note), params: big_params, as: :json
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.parsed_body["errors"]).to be_present
      end

      it "dataがオブジェクトでないと400" do
        patch book_handwritten_note_path(book, note),
              params: { handwritten_note: { data: "broken" } }, as: :json
        expect(response).to have_http_status(:bad_request)
      end

      it "data・title以外だけのリクエストは400" do
        patch book_handwritten_note_path(book, note),
              params: { handwritten_note: { unknown: 1 } }, as: :json
        expect(response).to have_http_status(:bad_request)
      end

      it "他人のノートには保存できない" do
        patch book_handwritten_note_path(other_book, other_note), params: scene_params, as: :json
        expect(response).to have_http_status(:not_found)
      end
    end

    describe "PATCH /books/:book_id/handwritten_notes/:id/thumbnail" do
      it "サムネイルを保存できる" do
        patch thumbnail_book_handwritten_note_path(book, note),
              params: { thumbnail: fixture_file_upload("sample.png", "image/png") }
        expect(response).to have_http_status(:no_content)
        expect(note.reload.thumbnail_s3).to be_attached
      end

      it "ファイルがないと400" do
        patch thumbnail_book_handwritten_note_path(book, note)
        expect(response).to have_http_status(:bad_request)
      end

      it "他人のノートには保存できない" do
        patch thumbnail_book_handwritten_note_path(other_book, other_note),
              params: { thumbnail: fixture_file_upload("sample.png", "image/png") }
        expect(response).to have_http_status(:not_found)
      end
    end

    describe "DELETE /books/:book_id/handwritten_notes/:id" do
      it "ノートを削除して本詳細へリダイレクトする" do
        note
        expect {
          delete book_handwritten_note_path(book, note)
        }.to change(HandwrittenNote, :count).by(-1)
        expect(response).to redirect_to(book_path(book))
      end

      it "他人のノートは削除できない" do
        other_note
        expect {
          delete book_handwritten_note_path(other_book, other_note)
        }.not_to change(HandwrittenNote, :count)
        expect(response).to have_http_status(:not_found)
      end
    end

    describe "本詳細画面" do
      it "ノート一覧と追加ボタンが表示される" do
        note.update!(title: "読書マップ")
        get book_path(book)
        expect(response.body).to include("handwritten-note-list")
        expect(response.body).to include("読書マップ")
      end
    end
  end
end
