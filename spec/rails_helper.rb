# This file is copied to spec/ when you run 'rails generate rspec:install'
require 'spec_helper'
ENV['RAILS_ENV'] ||= 'test'
require_relative '../config/environment'

abort("The Rails environment is running in production mode!") if Rails.env.production?

require 'rspec/rails'

require "view_component/test_helpers"

# github action用
require 'dotenv'
Dotenv.load('.env.test') if Rails.env.test?

# 外部HTTPリクエストをすべて遮断
require 'webmock/rspec'
WebMock.disable_net_connect!(allow_localhost: true)

begin
  ActiveRecord::Migration.maintain_test_schema!
rescue ActiveRecord::PendingMigrationError => e
  abort e.to_s.strip
end

Dir[Rails.root.join('spec/support/**/*.rb')].each { |f| require f }

RSpec.configure do |config|
  config.fixture_paths = [
    Rails.root.join('spec/fixtures')
  ]

  config.use_transactional_fixtures = true
  config.filter_rails_from_backtrace!

  config.include FactoryBot::Syntax::Methods
  config.include Devise::Test::IntegrationHelpers, type: :request
  config.include Devise::Test::IntegrationHelpers, type: :system
  config.include GuestUserHelper
  config.include ViewComponent::TestHelpers, type: :component
  config.include WebAuthnHelper, type: :request

  config.before(:each) do
    Bullet.enable = true if Bullet.respond_to?(:enable=)
    Bullet.start_request if Bullet.enabled?
  end

  config.after(:each) do
    if Bullet.enabled?
      Bullet.perform_out_of_channel_notifications if Bullet.notification?
      Bullet.end_request
    end
  end
end

Shoulda::Matchers.configure do |config|
  config.integrate do |with|
    with.test_framework :rspec
    with.library :rails
  end
end
