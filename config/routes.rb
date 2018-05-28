Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  # get '/users/:id', to: 'users#show', as: 'user'

  # resources :coins, path: '/admin/coins'
  # scope module: 'admin' do
  #   resources :coins
  # end

  # namespace :admin do
  #   resources :coins
  # end

  # scope '/admin' do
  #   resources :coins
  # end

  # namespace :admin, path: '/' do
  #   resources :coins
  # end

  # get '/user', action: 'show', controller: 'users'

  root 'welcome#index'

  # Sidekiq Monitoring
  require 'sidekiq/web'
  authenticate :user, lambda { |u| u.admin? } do
    # Sidekiq::Web.set :session_secret, Rails.application.secrets[:secret_key_base]
    mount Sidekiq::Web => '/sidekiq'
  end

  # HELP
  get '/help', to: 'help#index', as: 'help'
  get '/donations', to: 'help#donations', as: 'donations'

  # CLASES
  get '/classes', to: 'classes#index', as: 'classes'

  # USERS
  devise_for :users

  # EXCHANGES
  resources :exchanges, only: [:show]

  # COINS
  resources :coins, only: [:show]
  post '/coins/analyze', to: 'coins#analyze', as: 'analyze_coin'
  get '/coins/search', to: 'coins#show', as: 'search_coin'

  # FILTERS
  resources :filters, only: [:index]
  post '/filters/analyze', to: 'filters#analyze', as: 'analyze_filter'
end
