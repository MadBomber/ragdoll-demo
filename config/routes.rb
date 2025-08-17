Rails.application.routes.draw do
  # Landing page
  root "home#index"
  
  # Mount the Ragdoll Rails Engine
  mount Ragdoll::Rails::Engine, at: "/ragdoll"
  
  # Legacy routes - now handled by the engine
  # All Ragdoll functionality is available at /ragdoll/*
  
  # Health check
  get "up" => "rails/health#show", as: :rails_health_check
  
  # Favicon
  get "favicon.ico" => redirect("/icon.png")
  
  # ActionCable
  mount ActionCable.server => "/cable"
end
