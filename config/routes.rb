# frozen_string_literal: true

Rails.application.routes.draw do
  root 'home#index'

  get 'login', to: 'login#index', as: :login
  get 'logout', to: 'sessions#destroy', as: :logout

  post 'telegram/updates', to: 'telegram#create', defaults: { format: :json }

  get 'account/integrations/telegram', to: 'account#link_telegram_account', as: :link_telegram_account
  get 'auth/:provider/callback', to: 'sessions#create', as: :oauth_callback

  resources :account, only: [:index]

  resources :domains, param: :root, constraints: { root: %r{[^/]+} } do
    get 'delete', on: :member
  end
end
