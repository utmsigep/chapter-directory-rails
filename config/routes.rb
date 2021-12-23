Rails.application.routes.draw do
  get 'map/index'
  resources :regions
  resources :districts
  resources :chapters

  # Defines the root path route ("/")
  root 'map#index'
end
