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
end
