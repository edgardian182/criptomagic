Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  # get '/users/:id', to: 'users#show', as: 'user'

  root 'welcome#index'

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

  resources :exchanges, only: [:show]
  resources :coins, only: [:show]
  post '/coins/analyze', to: 'coins#analyze', as: 'analyze_coin'
  resources :filters, only: [:index]
  post '/filters/analyze', to: 'filters#analyze', as: 'analyze_filter'

end
