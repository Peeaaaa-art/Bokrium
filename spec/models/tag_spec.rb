# frozen_string_literal: true

require 'rails_helper'

RSpec.describe UserTag, type: :model do
  describe "バリデーション" do
    it "有効なタグは保存できる" do
      tag = build(:user_tag, name: "読書", user: create(:user))
      expect(tag).to be_valid
    end

    it "名前が空だと無効" do
      tag = build(:user_tag, name: "", user: create(:user))
      expect(tag).not_to be_valid
      expect(tag.errors[:name]).to include("を入力してください")
    end

    it "名前が31文字だと無効" do
      tag = build(:user_tag, name: "あ" * 31, user: create(:user))
      expect(tag).not_to be_valid
      expect(tag.errors[:name]).to include("は30文字以内で入力してください")
    end

    it "ユーザーが紐づいていないと無効" do
      tag = build(:user_tag, name: "読書", user: nil)
      expect(tag).not_to be_valid
      expect(tag.errors[:user]).to include("を入力してください")
    end
  end

  describe "スコープ" do
    it "owned_byスコープで特定のユーザーのタグのみ取得できる" do
      user1 = create(:user)
      user2 = create(:user)
      tag1 = create(:user_tag, name: "哲学", user: user1)
      tag2 = create(:user_tag, name: "小説", user: user2)

      results = UserTag.owned_by(user1)
      expect(results).to include(tag1)
      expect(results).not_to include(tag2)
    end
  end
end
