Rails.application.routes.draw do
  # Mount the Ragdoll Rails Engine
  mount Ragdoll::Rails::Engine, at: "/ragdoll"
  
  # Redirect root to the engine
  root to: redirect("/ragdoll")
  
  # Legacy routes - now handled by the engine
  # All Ragdoll functionality is available at /ragdoll/*
  
  # Health check
  get "up" => "rails/health#show", as: :rails_health_check
  
  # Favicon
  get "favicon.ico" => redirect("/icon.png")
  
  # ActionCable
  mount ActionCable.server => "/cable"
end
