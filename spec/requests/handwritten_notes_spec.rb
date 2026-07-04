require 'rails_helper'

RSpec.describe "HandwrittenNotes", type: :request do
  let(:user) { FactoryBot.create(:user) }
  let(:book) { FactoryBot.create(:book, user: user) }
  let(:other_user) { FactoryBot.create(:user) }
  let(:other_book) { FactoryBot.create(:book, user: other_user) }

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
      get book_handwritten_note_path(book)
      expect(response).to redirect_to(new_user_session_path)
    end
  end

  describe "ログイン済み" do
    before do
      post user_session_path, params: {
        user: { email: user.email, password: user.password }
      }
    end

    describe "GET /books/:book_id/handwritten_note" do
      it "初回アクセスで空のノートが作られる" do
        expect {
          get book_handwritten_note_path(book)
        }.to change(HandwrittenNote, :count).by(1)
        expect(response).to have_http_status(:ok)
        expect(HandwrittenNote.last).to have_attributes(user: user, book: book, data: {})
      end

      it "2回目以降は既存ノートを使う" do
        note = FactoryBot.create(:handwritten_note, user: user, book: book)
        expect {
          get book_handwritten_note_path(book)
        }.not_to change(HandwrittenNote, :count)
        expect(response.body).to include("handwritten-note-root")
        expect(response.body).to include(book_handwritten_note_path(book))
        expect(HandwrittenNote.order(:position, :id).first).to eq(note)
      end

      it "他人の本のノートにはアクセスできない" do
        get book_handwritten_note_path(other_book)
        expect(response).to have_http_status(:not_found)
      end
    end

    describe "PATCH /books/:book_id/handwritten_note" do
      it "シーンJSONを保存できる" do
        patch book_handwritten_note_path(book), params: scene_params, as: :json
        expect(response).to have_http_status(:no_content)

        note = book.handwritten_notes.first
        expect(note.data["elements"].first["type"]).to eq("freedraw")
        expect(note.data["appState"]["viewBackgroundColor"]).to eq("#ffffff")
      end

      it "保存後に再取得すると同じシーンが返る" do
        patch book_handwritten_note_path(book), params: scene_params, as: :json
        get book_handwritten_note_path(book)
        expect(response.body).to include("freedraw")
      end

      it "2MBを超えるdataは保存できない" do
        big_params = { handwritten_note: { data: { elements: [ { text: "a" * 2.megabytes } ] } } }
        patch book_handwritten_note_path(book), params: big_params, as: :json
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.parsed_body["errors"]).to be_present
      end

      it "dataがオブジェクトでないと400" do
        patch book_handwritten_note_path(book),
              params: { handwritten_note: { data: "broken" } }, as: :json
        expect(response).to have_http_status(:bad_request)
      end

      it "他人の本には保存できない" do
        patch book_handwritten_note_path(other_book), params: scene_params, as: :json
        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
