# config/initializers/omniauth.rb

Rails.application.config.middleware.use OmniAuth::Builder do
  provider :line,
           ENV["LINE_LOGIN_CHANNEL_ID"],
           ENV["LINE_LOGIN_CHANNEL_SECRET"],
           scope: "profile openid",
           bot_prompt: "normal"  # LINE連携後にBot追加促す（任意）
end

OmniAuth.config.allowed_request_methods = [ :get, :post ]
OmniAuth.config.silence_get_warning = true
