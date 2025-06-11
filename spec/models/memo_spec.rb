require 'rails_helper'

RSpec.describe Memo, type: :model do
  describe "バリデーション" do
    let(:user) { create(:user) }
    let(:book) { create(:book, user: user) }

    it "ユーザー、書籍、コンテンツがあれば有効" do
      memo = build(:memo, user: user, book: book, content: "テストメモ")
      expect(memo).to be_valid
    end

    it "content が 10,000 文字なら有効" do
      memo = build(:memo, user: user, book: book, content: "あ" * 10_000)
      expect(memo).to be_valid
    end

    it "content が 10,001 文字だと無効" do
      memo = build(:memo, user: user, book: book, content: "あ" * 10_001)
      expect(memo).not_to be_valid
      expect(memo.errors[:content]).to include(": メモは10,000文字以内で入力してください")
    end
  end

  describe "初期状態" do
    it "デフォルトでは非公開（only_me）になっている" do
      memo = FactoryBot.build(:memo)
      expect(memo.visibility?(:only_me)).to be true
      expect(memo.shared?).to be false
    end
  end

  describe "#visibility?" do
    it "公開範囲が正しく判定される" do
      memo = FactoryBot.build(:memo, visibility: Memo::VISIBILITY[:public_site])
      expect(memo.visibility?(:public_site)).to be true
    end
  end

  describe "#shared?" do
    it "link_only や public_site の場合 true になる" do
      memo = FactoryBot.build(:memo, visibility: Memo::VISIBILITY[:link_only])
      expect(memo.shared?).to be true
    end
  end

  describe "#public_url" do
    it "sharedでトークンがある場合、URLが返る" do
      memo = FactoryBot.build(:memo, visibility: Memo::VISIBILITY[:link_only], public_token: "abc123")
      expect(memo.public_url).to include("abc123")
    end

    it "トークンがない場合はnilになる" do
      memo = FactoryBot.build(:memo, visibility: Memo::VISIBILITY[:link_only], public_token: nil)
      expect(memo.public_url).to be_nil
    end
  end
end
