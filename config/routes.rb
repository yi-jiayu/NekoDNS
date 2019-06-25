Rails.application.routes.draw do
  root 'home#index'

  get "login", to: "login#index", as: :login
  get "logout", to: "sessions#destroy", as: :logout
  get 'account', to: 'account#index', as: :account

  get 'account/integrations/telegram', to: 'account#link_telegram_account', as: :link_telegram_account
  get "auth/:provider/callback", to: "sessions#create", as: :oauth_callback
  post "telegram/webhook", to: "telegram#webhook"

  resources :domains
end
