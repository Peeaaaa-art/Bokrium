# spec/models/user_spec.rb
require 'rails_helper'

RSpec.describe User, type: :model do
  it "有効なファクトリを持つ" do
    expect(build(:user)).to be_valid
  end

  it "メールが必須であること" do
    user = build(:user, email: nil)
    expect(user).not_to be_valid
  end

  it "パスワードが必須であること" do
    user = build(:user, password: nil)
    expect(user).not_to be_valid
  end

  describe "名前のバリデーション" do
    it "名前が50文字以内なら有効である" do
      user = build(:user, name: "あ" * 50)
      expect(user).to be_valid
    end

    it "名前が51文字以上だと無効である" do
      user = build(:user, name: "あ" * 51)
      expect(user).not_to be_valid
      expect(user.errors[:name]).to include(": 名前は50文字以内で入力してください")
    end
  end
end
