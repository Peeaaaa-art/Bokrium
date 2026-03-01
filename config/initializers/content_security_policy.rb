Rails.application.configure do
  config.content_security_policy do |policy|
    policy.default_src :self, :https

    policy.font_src    :self, :https, :data, "https://fonts.googleapis.com", "https://fonts.gstatic.com"
    policy.img_src     :self, :https, :data,
        "https://assets.bokrium.com", "https://lib.bokrium.com", "https://cdn.bokrium.com", "https://img.bokrium.com", "https://img.hanmoto.com", "https://bokrium-bucket.s3.ap-northeast-1.amazonaws.com",
        "https://books.google.com", "https://thumbnail.image.rakuten.co.jp", "https://webservice.rakuten.co.jp", "https://image.rakuten.co.jp", "https://rimg.jp"
    policy.object_src  :none
    policy.script_src  :self, :https,  "https://assets.bokrium.com"
    policy.style_src   :self, :https,  "https://assets.bokrium.com", "https://fonts.googleapis.com"

    if Rails.env.development?
      script_srcs = policy.script_src + [ :unsafe_eval, "http://localhost:3036" ]
      style_srcs = policy.style_src + [ :unsafe_inline, "http://localhost:3036" ]
      connect_srcs = Array(policy.connect_src) + [ :self, "http://localhost:3036", "ws://localhost:3036" ]

      policy.script_src(*script_srcs)
      policy.style_src(*style_srcs)
      policy.connect_src(*connect_srcs)
    else
      policy.connect_src :self
    end
  end

  config.content_security_policy_report_only = true
end
