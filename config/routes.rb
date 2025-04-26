Rails.application.routes.draw do
  get "search", to: "search#index", as: :search_books
  get "search/barcode", to: "search#barcode"
  post 'search/scan_isbn', to: 'search#search_isbn_turbo', as: :scan_isbn
  get "books/search_isbn_turbo", to: "search#search_isbn_turbo"

  devise_for :users, controllers: { registrations: "users/registrations" }
  resources :users, only: [ :index, :show ]

  resources :books do
    resources :memos, only: [ :create, :new, :edit, :update, :destroy ]
    resources :images, only: [ :create, :destroy ]
  end

  root "welcome#index"
  get "up" => "rails/health#show", as: :rails_health_check
end

# 公式リファレンス https://guides.rubyonrails.org/routing.html
