Rails.application.routes.draw do
  # Ragdoll Engine Demo Routes
  root "dashboard#index"
  
  # Dashboard and Analytics
  get "dashboard" => "dashboard#index"
  get "analytics" => "dashboard#analytics"
  
  # Document Management
  resources :documents do
    member do
      get :preview
      post :reprocess
      get :download
    end
    collection do
      post :bulk_upload
      post :bulk_delete
      post :bulk_reprocess
      get :status
      post :upload_async
    end
  end
  
  # Search Interface
  get "search" => "search#index"
  post "search" => "search#search"
  # Redirect old search analytics to main analytics page
  get "search/analytics" => redirect("/analytics")
  
  # Configuration
  get "configuration" => "configuration#index"
  patch "configuration" => "configuration#update"
  
  # API endpoints for AJAX interactions
  namespace :api do
    namespace :v1 do
      resources :documents, only: [:index, :show, :create, :update, :destroy] do
        member do
          post :reprocess
        end
      end
      post "search" => "search#search"
      get "analytics" => "analytics#index"
      get "system_stats" => "system#stats"
    end
  end
  
  # Health check
  get "up" => "rails/health#show", as: :rails_health_check
  
  # Favicon
  get "favicon.ico" => redirect("/icon.png")
  
  # ActionCable
  mount ActionCable.server => "/cable"
end
