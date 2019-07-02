# frozen_string_literal: true

Rails.application.routes.draw do
  root 'home#index'

  get 'login', to: 'login#index', as: :login
  get 'logout', to: 'sessions#destroy', as: :logout

  post 'telegram/updates', to: 'telegram#create', defaults: { format: :json }

  get 'auth/:provider/callback', to: 'sessions#create', as: :oauth_callback

  resources :account, only: [:index]

  resources :domains, except: [:edit, :update], param: :root, constraints: { root: %r{[^/]+} } do
    get 'delete', on: :member
  end

  resources :credentials, except: [:edit, :delete]

  namespace :integrations do
    get 'telegram/callback', to: 'telegram#callback'
    delete 'telegram', to: 'telegram#destroy'
  end
end
