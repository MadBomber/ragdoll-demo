# frozen_string_literal: true

# MissionControl::Jobs configuration
# Disable authentication in development mode

if Rails.env.development?
  Rails.application.config.to_prepare do
    if defined?(MissionControl::Jobs)
      # Override the engine's authentication completely
      MissionControl::Jobs::Engine.class_eval do
        def self.authenticate_with(&block)
          # Do nothing in development - disable authentication completely
        end
      end

      # Override ApplicationController if it exists
      if defined?(MissionControl::Jobs::ApplicationController)
        MissionControl::Jobs::ApplicationController.class_eval do
          # Remove all before_actions by clearing the callback chain
          reset_callbacks :process_action
          
          # Override authenticate method to always return true
          define_method :authenticate do
            true
          end
          
          # Provide a fake current_user
          define_method :current_user do
            OpenStruct.new(
              id: 1, 
              name: "Development User", 
              email: "dev@example.com"
            )
          end
          
          # Override any authorization checks
          define_method :authorized? do
            true
          end
          
          private
          
          # Ensure no authentication is required
          def require_authentication
            # Do nothing
          end
        end
      end
    end
  end
end