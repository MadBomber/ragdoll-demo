# frozen_string_literal: true

# Configure timeouts for large file uploads
Rails.application.configure do
  # Disable Rack::Timeout for development to allow long uploads
  if Rails.env.development?
    config.middleware.delete Rack::Timeout::Middleware if defined?(Rack::Timeout::Middleware)
  end
  
  # Set longer timeout for production if Rack::Timeout is used
  if defined?(Rack::Timeout)
    Rack::Timeout.service_timeout = 600  # 10 minutes
  end
end