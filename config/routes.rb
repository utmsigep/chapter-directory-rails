Rails.application.routes.draw do
  devise_for :users

  get 'map/index', to: redirect('/')
  get 'map/data', to: 'map#map_data', as: 'map_data'

  authenticate :user do
    namespace :admin do
      get '/', to: redirect('/admin/chapters')

      # Import Chapters
      get 'chapters/import', to: 'chapters#import'
      post 'chapters/import', to: 'chapters#do_import'

      # Filtered Map Data Feeds
      get 'regions/:id/chapters', to: 'regions#chapters', as: 'region_chapters'
      get 'districts/:id/chapters', to: 'districts#chapters', as: 'district_chapters'

      resources :regions
      resources :districts
      resources :chapters
    end
  end

  # Defines the root path route ("/")
  root 'map#index'
end
