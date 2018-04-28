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

  resources :exchanges, only: [:show]
  resources :coins, only: [:show]

end
