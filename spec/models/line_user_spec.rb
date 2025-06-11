# spec/models/line_user_spec.rb
require 'rails_helper'

RSpec.describe LineUser, type: :model do
  describe "バリデーション" do
    let(:user1) { FactoryBot.create(:user) }
    let(:user2) { FactoryBot.create(:user) }

    it "line_id がユニークなら有効" do
      line_user = LineUser.new(user: user1, line_id: "U1234567890")
      expect(line_user).to be_valid
    end

    it "同じ line_id があると無効" do
      LineUser.create!(user: user1, line_id: "U1234567890")
      duplicate = LineUser.new(user: user2, line_id: "U1234567890")
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:line_id]).to include("はすでに存在します")
    end

    it "line_id が nil の場合は保存できる" do
      line_user = LineUser.new(user: user1, line_id: nil)
      expect(line_user).to be_valid
    end

    it "line_id が nil 同士でも複数登録できる" do
      LineUser.create!(user: user1, line_id: nil)
      another = LineUser.new(user: user2, line_id: nil)
      expect(another).to be_valid
    end
  end
end
