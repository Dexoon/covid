Rails.application.routes.draw do
  resources :bids
  resources :users
  resources :regions
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html

  get '/webhook', to: 'application#webhook'
  post '/webhook', to: 'application#webhook'

  require 'sidekiq/web'
  mount Sidekiq::Web => '/sidekiq'

  telegram_webhook TelegramWebhooksController
end
