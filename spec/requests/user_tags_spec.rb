require 'rails_helper'

RSpec.describe "UserTags", type: :request do
  let(:user) { FactoryBot.create(:user) }

  describe "未ログイン時" do
    it "POST /user_tags はサインインへリダイレクトする" do
      post user_tags_path, params: { user_tag: { name: "小説" } }
      expect(response).to redirect_to(new_user_session_path)
    end
  end

  describe "ログイン時" do
    before { sign_in user }

    it "タグを作成できる" do
      expect {
        post user_tags_path, params: { user_tag: { name: "小説" } }
      }.to change(user.user_tags, :count).by(1)
    end
  end
end
