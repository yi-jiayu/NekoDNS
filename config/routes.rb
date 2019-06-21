Rails.application.routes.draw do
  root 'home#index'

  get "login", to: "login#index", as: :login
  get "auth/:provider/callback", to: "sessions#create", as: :oauth_callback
  get "logout", to: "sessions#destroy", as: :logout
end
