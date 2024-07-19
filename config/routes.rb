Rails.application.routes.draw do
  devise_for :users

  get 'map/index', to: redirect('/')
  get 'map/data', to: 'map#map_data', as: 'map_data'

  authenticate :user do
    namespace :admin do
      get '/', to: 'dashboard#index'

      # Import Chapters
      get 'chapters/import', to: 'chapters#import'
      post 'chapters/import', to: 'chapters#do_import'

      # Filtered Map Data Feeds
      get 'districts/:id/chapters', to: 'districts#chapters', as: 'district_chapters'

      resources :districts
      resources :chapters
    end
  end

  # Defines the root path route ("/")
  root 'map#index'
end
