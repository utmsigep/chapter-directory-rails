Rails.application.routes.draw do
  get 'map/index'
  get 'map/data', to: 'map#map_data', as: 'map_data'

  namespace :admin do
    get '/', to: redirect('/admin/chapters')

    resources :regions
    resources :districts
    resources :chapters

    # Filtered Map Data Feeds
    get 'admin/regions/:id/chapters', to: 'regions#chapters', as: 'region_chapters'
    get 'admin/districts/:id/chapters', to: 'districts#chapters', as: 'district_chapters'
  end

  # Defines the root path route ("/")
  root 'map#index'
end
