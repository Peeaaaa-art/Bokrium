Rails.application.routes.draw do
  devise_for :users, controllers: {
    registrations: "users/registrations",
    confirmations: "users/confirmations",
    omniauth_callbacks: "users/omniauth_callbacks"
    },
    omniauth_providers: [:line]

  get "/up", to: proc { [ 200, {}, [ "OK" ] ] }
  get "explore/index"
  get "explore/suggestions"
  get "search", to: "search#index", as: :search_books
  get "search/barcode", to: "search#barcode", as: :search_barcode
  get "search/isbn_turbo", to: "search#search_isbn_turbo", as: :search_isbn_turbo
  get "search/search_google_books", to: "search#search_google_books", as: :search_google_books
  post "/presigned_url", to: "uploads#presigned_url"
  post "/callback", to: "line_webhooks#callback"
  patch "/line_notifications/toggle", to: "line_notifications#toggle", as: :toggle_notifications
  post "line_notifications/trigger", to: "line_notifications#trigger"
  resource :line_user, only: [ :destroy ]

  get "mypage", to: "users#show", as: :mypage

  resources :books do
    resources :memos, only: [ :create, :new, :edit, :update, :destroy ]
    resources :images, only: [ :create, :destroy ]

    post "toggle_tag", on: :member

    collection do
      get :tag_filter
    end
  end

  resources :tags, only: [ :create, :update, :destroy ]

  resources :shared_memos, only: [ :show ], param: :token do
    resource :like_memo, only: [ :create, :destroy ]
  end

  resources :public_bookshelf, only: [ :index, :show ]

  get "/explore", to: "explore#index", as: :explore

  root "welcome#index"

  namespace :guest do
    resources :books, only: [ :index, :show ]
    resources :starter_books, only: [ :index, :show ]
  end

  get "faq", to: "pages#faq"
  get "terms", to: "pages#terms"
  get "privacy", to: "pages#privacy"
  get "/manifest.json", to: "pwa#manifest", defaults: { format: :json }
end

# 公式リファレンス https://guides.rubyonrails.org/routing.html
Rails.logger.info "[DEBUG ROUTES] OmniAuth Providers: #{Devise.omniauth_configs.keys.inspect}"