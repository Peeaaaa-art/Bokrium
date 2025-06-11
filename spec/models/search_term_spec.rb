# spec/models/search_term_spec.rb
require 'rails_helper'

RSpec.describe SearchTerm, type: :model do
  describe "バリデーション" do
    let(:user) { FactoryBot.create(:user) }

    it "有効なデータなら保存できる" do
      search_term = described_class.new(user: user, term: "検索ワード")
      expect(search_term).to be_valid
    end

    it "term が 255 文字以内なら有効" do
      search_term = described_class.new(user: user, term: "あ" * 255)
      expect(search_term).to be_valid
    end

    it "term が 256 文字以上だと無効" do
      search_term = described_class.new(user: user, term: "あ" * 256)
      expect(search_term).to be_invalid
      expect(search_term.errors[:term]).to include(": 255文字以内で入力してください")
    end
  end
end
