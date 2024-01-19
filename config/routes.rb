Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check
  root 'users#index'
  resources :daily_records
  resources :users
end
