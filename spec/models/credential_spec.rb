require 'rails_helper'

RSpec.describe Credential, type: :model do
  describe "associations" do
    it { should belong_to(:user) }
  end

  describe "validations" do
    subject { build(:credential) }

    it { should validate_presence_of(:external_id) }
    it { should validate_uniqueness_of(:external_id) }
    it { should validate_presence_of(:public_key) }
    it { should validate_presence_of(:sign_count) }
    it { should validate_numericality_of(:sign_count).only_integer.is_greater_than_or_equal_to(0) }
  end

  describe "#display_name" do
    context "ニックネームが設定されている場合" do
      let(:credential) { create(:credential, nickname: "My MacBook Pro") }

      it "ニックネームを返す" do
        expect(credential.display_name).to eq("My MacBook Pro")
      end
    end

    context "ニックネームが設定されていない場合" do
      let(:credential) { create(:credential, nickname: nil) }

      it "デフォルトの表示名を返す" do
        expect(credential.display_name).to match(/^パスキー \d{4}\/\d{2}\/\d{2}$/)
      end
    end

    context "ニックネームが空文字の場合" do
      let(:credential) { create(:credential, nickname: "") }

      it "デフォルトの表示名を返す" do
        expect(credential.display_name).to match(/^パスキー \d{4}\/\d{2}\/\d{2}$/)
      end
    end
  end

  describe "データベース制約" do
    let(:user) { create(:user) }
    let!(:credential) { create(:credential, user: user) }

    it "同じ external_id を持つレコードは作成できない" do
      duplicate_credential = build(:credential, external_id: credential.external_id)
      expect(duplicate_credential).not_to be_valid
      expect(duplicate_credential.errors[:external_id]).to be_present
    end

    it "sign_count は負の数にできない" do
      credential.sign_count = -1
      expect(credential).not_to be_valid
      expect(credential.errors[:sign_count]).to be_present
    end

    it "sign_count は整数でなければならない" do
      credential.sign_count = 1.5
      expect(credential).not_to be_valid
      expect(credential.errors[:sign_count]).to be_present
    end
  end

  describe "ユーザーとの関連" do
    let(:user) { create(:user) }
    let!(:credential1) { create(:credential, user: user) }
    let!(:credential2) { create(:credential, user: user) }

    it "ユーザーは複数のパスキーを持つことができる" do
      expect(user.credentials.count).to eq(2)
      expect(user.credentials).to include(credential1, credential2)
    end

    it "ユーザーが削除されるとパスキーも削除される" do
      expect {
        user.destroy
      }.to change(Credential, :count).by(-2)
    end
  end
end
