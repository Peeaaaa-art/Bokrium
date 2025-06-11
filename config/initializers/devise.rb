# frozen_string_literal: true

Devise.setup do |config|
  config.mailer_sender = "Bokrium <support@bokrium.com>"

  require "devise/orm/active_record"

  config.maximum_attempts = 10

  config.unlock_strategy = :email

  config.lock_strategy = :failed_attempts

  config.unlock_in = 1.hour

  config.case_insensitive_keys = [ :email ]

  config.strip_whitespace_keys = [ :email ]

  config.skip_session_storage = [ :http_auth ]

  config.stretches = Rails.env.test? ? 1 : 12

  config.reconfirmable = true

  config.expire_all_remember_me_on_sign_out = true

  config.password_length = 6..128

  config.email_regexp = /\A[^@\s]+@[^@\s]+\z/

  config.reset_password_within = 6.hours

  config.sign_out_via = :delete

  config.omniauth :line,
                  ENV["LINE_LOGIN_CHANNEL_ID"],
                  ENV["LINE_LOGIN_CHANNEL_SECRET"],
                  scope: "profile openid",
                  bot_prompt: "normal",
                  name: :line

  config.omniauth_path_prefix = "/users/auth"

  config.responder.error_status = :unprocessable_entity
  config.responder.redirect_status = :see_other
end

OmniAuth.config.allowed_request_methods = [ :get ]
OmniAuth.config.silence_get_warning = true
