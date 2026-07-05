Rails.application.configure do
  config.content_security_policy do |policy|
    policy.default_src :self, :https

    policy.font_src    :self, :https, :data, "https://fonts.googleapis.com", "https://fonts.gstatic.com"
    policy.img_src     :self, :https, :data,
        "https://assets.bokrium.com", "https://lib.bokrium.com", "https://cdn.bokrium.com", "https://img.bokrium.com", "https://img.hanmoto.com",
        "https://books.google.com", "https://thumbnail.image.rakuten.co.jp", "https://webservice.rakuten.co.jp", "https://image.rakuten.co.jp", "https://rimg.jp"
    policy.object_src  :none
    # scriptは自前オリジン+アセットCDNのみ(包括的な:httpsを許可しない)。
    # インラインscript・インラインイベントハンドラは全廃済みのためunsafe_inline不要
    policy.script_src  :self, "https://assets.bokrium.com"
    # style属性・<style>ブロック(public_bookshelf等)・Turboのプログレスバーが
    # インラインCSSを使うためunsafe_inlineを許可(script側が絞られていれば実害は限定的)
    policy.style_src   :self, :unsafe_inline, "https://assets.bokrium.com", "https://fonts.googleapis.com"

    if Rails.env.development?
      script_srcs = policy.script_src + [ :unsafe_eval, "http://localhost:3036" ]
      style_srcs = (policy.style_src + [ :unsafe_inline, "http://localhost:3036" ]).uniq
      connect_srcs = Array(policy.connect_src) + [ :self, "http://localhost:3036", "ws://localhost:3036" ]

      policy.script_src(*script_srcs)
      policy.style_src(*style_srcs)
      policy.connect_src(*connect_srcs)
    else
      policy.connect_src :self
    end
  end
end
