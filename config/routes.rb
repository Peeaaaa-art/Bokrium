Rails.application.routes.draw do
  get "search", to: "search#index", as: :search_books
  get "search/barcode", to: "search#barcode"
  get "search/search_isbn_turbo", to: "search#search_isbn_turbo"
  get "search/search_google_books", to: "search#search_google_books", as: :search_google_books
  post "/presigned_url", to: "uploads#presigned_url"

  devise_for :users, controllers: { registrations: "users/registrations" }
  resources :users, only: [ :index, :show ]

  resources :books do
    resources :memos, only: [ :create, :new, :edit, :update, :destroy ]
    resources :images, only: [ :create, :destroy ]
    post "assign_tag", on: :member
    post "toggle_tag", on: :member
  end

  resources :tags, only: [ :create, :update, :destroy ]

  root "welcome#index"
  get "up" => "rails/health#show", as: :rails_health_check
end

# 公式リファレンス https://guides.rubyonrails.org/routing.html
