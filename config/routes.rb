Rails.application.routes.draw do
  get 'map/index'
  resources :regions
  resources :districts
  resources :chapters

  # Filtered Map Data Feeds
  get 'regions/:id/chapters', to: 'regions#chapters', as: 'region_chapters'
  get 'districts/:id/chapters', to: 'districts#chapters', as: 'district_chapters'

  # Defines the root path route ("/")
  root 'map#index'
end
