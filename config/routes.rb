Rails.application.routes.draw do
  get 'map/index'
  get 'map/data', to: 'map#map_data', as: 'map_data'

  resources :regions
  resources :districts
  resources :chapters

  # Filtered Map Data Feeds
  get 'regions/:id/chapters', to: 'regions#chapters', as: 'region_chapters'
  get 'districts/:id/chapters', to: 'districts#chapters', as: 'district_chapters'

  # Defines the root path route ("/")
  root 'map#index'
end
