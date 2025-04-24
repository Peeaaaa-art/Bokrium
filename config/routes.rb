Rails.application.routes.draw do
  devise_for :users, controllers: { registrations: "users/registrations" }
  resources :users, only: [ :index, :show ]
  resources :books do
    resources :memos, only: [ :create, :new, :edit, :update, :destroy ]
    resources :images, only: [ :create, :destroy ]
    member do
      post :add_memo_form
    end
    collection do
      get :search_by_isbn
      get :search_by_author
    end
  end

  root "welcome#index"
  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check
end

# 公式リファレンス https://guides.rubyonrails.org/routing.html
