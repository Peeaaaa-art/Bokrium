Rails.application.routes.draw do
  devise_for :users, controllers: {
    registrations: "users/registrations",
    confirmations: "users/confirmations",
    passwords: "users/passwords",
    omniauth_callbacks: "users/omniauth_callbacks"
    },
    omniauth_providers: [ :line ]

  devise_scope :user do
    get  "users/password/send_reset_link", to: "users/passwords#send_reset_link", as: :send_reset_link_user_password
    post "users/password/trigger_reset",   to: "users/passwords#trigger_reset",   as: :trigger_reset_user_password

    get "users/email/edit",   to: "users/emails#edit",   as: :edit_user_email
    patch "users/email/update", to: "users/emails#update", as: :update_user_email

    get "users/auth/line/connect", to: "users/omniauth_callbacks#line_connect", as: :user_line_connect

    # Passkey 認証
    get  "users/webauthn_login", to: "users/webauthn_sessions#new", as: :new_user_webauthn_session
    post "users/webauthn_login", to: "users/webauthn_sessions#create", as: :user_webauthn_session

    # Passkey 登録・削除
    get    "users/credentials/new", to: "users/credentials#new", as: :new_user_credential
    post   "users/credentials",     to: "users/credentials#create", as: :user_credentials
    delete "users/credentials/:id", to: "users/credentials#destroy", as: :user_credential

    # Passkey 初期設定画面
    get  "users/passkey_setup",          to: "users/passkey_setup#show",     as: :setup_passkey
    post "users/passkey_setup/complete", to: "users/passkey_setup#complete", as: :complete_passkey_setup
    post "users/passkey_setup/skip",     to: "users/passkey_setup#skip",     as: :skip_passkey_setup

    # メール確認待ち（development のみ。letter_opener_web へのリンク用）
    if Rails.env.development?
      get "users/confirmation_pending", to: "users/registrations#confirmation_pending", as: :user_confirmation_pending
    end
  end

  get "/up", to: proc { [ 200, {}, [ "OK" ] ] }

  mount LetterOpenerWeb::Engine, at: "/letter_opener" if Rails.env.development?

  resources :donations, only: [ :index, :create ]
  get "donations/thank_you", to: "donations#thank_you"


  get "explore/suggestions"
  get "search", to: "search#index", as: :search_books
  get "search/barcode", to: "search#barcode", as: :search_barcode
  get "search/isbn_turbo", to: "search#search_isbn_turbo", as: :search_isbn_turbo
  get "search/search_google_books", to: "search#search_google_books", as: :search_google_books
  get "cover_proxy", to: "cover_proxy#show", as: :cover_proxy
  post "/presigned_url", to: "uploads#presigned_url"
  post "/callback", to: "line_webhooks#callback"

  patch "/line_notifications/toggle", to: "line_notifications#toggle", as: :toggle_notifications
  post "line_notifications/trigger", to: "line_notifications#trigger"
  resource :line_user, only: [ :destroy ]

  patch "toggle_email_notifications", to: "users#toggle_email_notifications", as: :toggle_email_notifications

  get "mypage", to: "users#show", as: :mypage

  resources :books do
    resources :memos, only: [ :create, :new, :edit, :update, :destroy ]
    resources :images, only: [ :create, :destroy ]
    resource :row, only: [ :show, :edit, :update ], controller: "books/rows"
    resource :tags, only: [], controller: "books/tags" do
      post :toggle
    end

    collection do
      get :autocomplete, to: "books/autocompletes#index"
      delete :clear_filters
    end
  end

  get "books/filters/filter", to: "books/tags#filter", as: :filter_books_tags

  resource :view_mode, only: [ :update ]


  resources :user_tags, only: [ :create, :update, :destroy ]

  resources :public_bookshelf, only: [ :index, :show ], param: :token do
    resource :like_memo, only: [ :create, :destroy ]
  end

  get "/explore", to: "explore#index", as: :explore

  root "welcome#index"

  namespace :guest do
    resources :books, only: [ :index, :show ] do
      collection do
        delete :clear_filters
        get :filter_tags, to: "books/tags#filter"
        get :autocomplete, to: "books/autocompletes#index"
      end
    end
    resources :starter_books, only: [ :index, :show ] do
      collection do
        get :five_layouts
        get :barcode_section
        get :bookshelf_section
        get :memo_section
        get :public_section
        get :guidebook_section
      end
    end
  end

  get "faq", to: "pages#faq"
  get "terms", to: "pages#terms"
  get "privacy", to: "pages#privacy"
  get "legal", to: "pages#legal"
  get "contact", to: "pages#contact"
  get "/manifest.json", to: "pwa#manifest", defaults: { format: :json }


  namespace :webhooks do
    post :stripe, to: "stripe#create"
    post :email_notifications, to: "email_notifications#create"
  end
  get "subscriptions/create", as: :create_subscrption
  post "subscription/cancel", to: "subscriptions#cancel", as: :cancel_subscription
end

# 公式リファレンス https://guides.rubyonrails.org/routing.html
