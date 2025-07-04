require 'rails_helper'

RSpec.describe 'User email confirmation', type: :system do
  before do
    ActionMailer::Base.deliveries.clear
    driven_by :rack_test
    ensure_guest_user
  end

  it 'Deviseから送信された確認リンクでメール認証できること' do
    visit new_user_registration_path
    fill_in 'floatingEmail', with: 'confirmtest@example.com'
    fill_in 'floatingPassword', with: 'password123'
    fill_in 'floatingPasswordConfirmation', with: 'password123'
    click_button 'アカウント登録'

    expect(page).to have_content '確認メールを送信しました'

    mail = ActionMailer::Base.deliveries.last
    expect(mail).not_to be_nil

    html_body = mail.html_part&.body&.decoded || mail.body.encoded
    match_data = html_body.match(/http:\/\/localhost:3000\/users\/confirmation\?confirmation_token=[\w\-]+/)
    raise "確認URLが見つかりません" if match_data.nil?

    confirmation_url = match_data[0]

    Capybara.reset_session!

    visit confirmation_url

    expect(page).to have_content 'メール確認が完了しました。Bokriumへようこそ！'
    expect(User.find_by(email: 'confirmtest@example.com').confirmed?).to be true
  end
end

RSpec.describe 'User login after confirmation', type: :system do
  let(:email) { 'confirmed@example.com' }
  let(:password) { 'password123' }

  before do
    driven_by :rack_test

    User.create!(
      email: email,
      password: password,
      confirmed_at: Time.current
    )
  end

  it 'メール確認済みのユーザーが正常にログインできること' do
    visit new_user_session_path
    fill_in 'メールアドレス', with: email
    fill_in 'パスワード', with: password
    click_button 'ログイン'

    expect(page).to have_content 'ログインしました'
    expect(page).to have_current_path(root_path)
  end
end
