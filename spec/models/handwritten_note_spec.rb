require 'rails_helper'

RSpec.describe HandwrittenNote, type: :model do
  describe "バリデーション" do
    let(:user) { create(:user) }
    let(:book) { create(:book, user: user) }

    it "ユーザー、書籍、空のdataがあれば有効" do
      note = build(:handwritten_note, user: user, book: book, data: {})
      expect(note).to be_valid
    end

    it "Excalidrawシーン形式のdataは有効" do
      scene = {
        "type" => "excalidraw",
        "version" => 2,
        "elements" => [ { "id" => "abc", "type" => "freedraw", "points" => [ [ 0, 0 ], [ 10, 12 ] ] } ],
        "appState" => { "viewBackgroundColor" => "#ffffff" }
      }
      note = build(:handwritten_note, user: user, book: book, data: scene)
      expect(note).to be_valid
    end

    it "dataがHashでないと無効" do
      note = build(:handwritten_note, user: user, book: book, data: "not a hash")
      expect(note).not_to be_valid
      expect(note.errors[:data]).to include(": 手書きデータの形式が不正です")
    end

    it "dataが2MBを超えると無効" do
      big_scene = { "elements" => [ { "text" => "a" * 2.megabytes } ] }
      note = build(:handwritten_note, user: user, book: book, data: big_scene)
      expect(note).not_to be_valid
      expect(note.errors[:data]).to include(": 手書きデータが大きすぎます（2MBまで）")
    end

    it "タイトルが100文字を超えると無効" do
      note = build(:handwritten_note, user: user, book: book, title: "あ" * 101)
      expect(note).not_to be_valid
    end
  end

  describe "関連" do
    it "書籍を削除すると手書きノートも削除される" do
      note = create(:handwritten_note)
      expect { note.book.destroy }.to change(HandwrittenNote, :count).by(-1)
    end
  end
end
