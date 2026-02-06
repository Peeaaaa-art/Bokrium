require 'rails_helper'

RSpec.describe 'Regexp::TimeoutError handling', type: :request do
  before do
    allow(Rails.logger).to receive(:warn)
  end

  it 'returns 400 for HTML requests and logs the exception' do
    allow_any_instance_of(SearchController).to receive(:index).and_raise(Regexp::TimeoutError.new('execution expired'))

    get search_books_path(type: 'title', query: 'x')

    expect(response).to have_http_status(:bad_request)
    expect(Rails.logger).to have_received(:warn).with(a_string_including('Regexp timeout: Regexp::TimeoutError'))
  end

  it 'returns a deterministic JSON payload for JSON requests' do
    allow_any_instance_of(SearchController).to receive(:index).and_raise(Regexp::TimeoutError.new('execution expired'))

    get search_books_path(type: 'title', query: 'x'), headers: { 'ACCEPT' => 'application/json' }

    expect(response).to have_http_status(:bad_request)
    expect(JSON.parse(response.body)).to eq({ 'error' => 'regexp_timeout' })
  end

  it 'returns 400 for Turbo Stream requests' do
    allow_any_instance_of(SearchController).to receive(:fetch_book_info).and_raise(Regexp::TimeoutError.new('execution expired'))

    get search_isbn_turbo_path(isbn: '9781234567897'), headers: { 'ACCEPT' => 'text/vnd.turbo-stream.html' }

    expect(response).to have_http_status(:bad_request)
  end

  it 'returns deterministic 400 JSON for Stripe webhook' do
    allow(Stripe::Webhook).to receive(:construct_event).and_raise(Regexp::TimeoutError.new('execution expired'))

    post webhooks_stripe_path, params: 'payload', headers: { 'HTTP_STRIPE_SIGNATURE' => 'sig' }

    expect(response).to have_http_status(:bad_request)
    expect(JSON.parse(response.body)).to eq({ 'error' => 'regexp_timeout' })
  end

  it 'returns deterministic 400 JSON for EmailNotifications webhook' do
    original_token = ENV['EMAIL_CRON_TOKEN']
    ENV['EMAIL_CRON_TOKEN'] = 'test-token'
    allow(EmailNotificationSender).to receive(:send_all).and_raise(Regexp::TimeoutError.new('execution expired'))

    post webhooks_email_notifications_path, headers: { 'X-EMAIL-CRON-TOKEN' => 'test-token' }

    expect(response).to have_http_status(:bad_request)
    expect(JSON.parse(response.body)).to eq({ 'status' => 'error', 'message' => 'regexp_timeout' })
  ensure
    ENV['EMAIL_CRON_TOKEN'] = original_token
  end

  it 'handles Regexp timeouts in LINE omniauth callback by redirecting safely' do
    OmniAuth.config.test_mode = true
    Rails.application.env_config['omniauth.auth'] = OmniAuth::AuthHash.new(
      provider: 'line',
      uid: 'uid-1',
      info: { name: 'Test User' }
    )
    allow(LineUser).to receive(:find_by).and_raise(Regexp::TimeoutError.new('execution expired'))

    get '/users/auth/line/callback'

    expect(response).to redirect_to(new_user_registration_url)
    expect(flash[:alert]).to eq(I18n.t('users.omniauth.regexp_timeout'))
  ensure
    OmniAuth.config.test_mode = false
    Rails.application.env_config.delete('omniauth.auth')
  end
end
