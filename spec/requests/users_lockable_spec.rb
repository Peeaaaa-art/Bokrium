require 'rails_helper'

RSpec.describe "Devise::Lockable", type: :request do
  let(:user) { create(:user, password: "password123") }

  before do
    ActionMailer::Base.deliveries.clear
  end

  it "ログイン失敗を10回するとアカウントがロックされ、解除メールが送信される" do
    10.times do
      post user_session_path, params: {
        user: {
          email: user.email,
          password: "wrong-password"
        }
      }
    end

    expect(user.reload.access_locked?).to be true
    expect(ActionMailer::Base.deliveries.size).to eq(1)

    mail = ActionMailer::Base.deliveries.last
    expect(mail.to).to include(user.email)
    expect(mail.subject).to include("アカウントのロック解除について")
    expect(mail.body.encoded).to include("unlock_token")
  end

  it "メールの解除リンクを踏むとアカウントが解除される" do
    user.lock_access!
    token = user.send_unlock_instructions

    get user_unlock_path(unlock_token: token)

    follow_redirect! # Deviseはredirectするため
    expect(response.body).to include("アカウントをロック解除しました。")
    expect(user.reload.access_locked?).to be false
  end
end
