# frozen_string_literal: true

# Enhanced logging configuration for debugging upload issues
Rails.application.configure do
  # Create custom logger for ragdoll operations
  if Rails.env.development?
    ragdoll_log_path = Rails.root.join('log', 'ragdoll_detailed.log')
    ragdoll_logger = Logger.new(ragdoll_log_path, 'daily')
    ragdoll_logger.level = Logger::DEBUG
    ragdoll_logger.formatter = proc do |severity, datetime, progname, msg|
      "[#{datetime.strftime('%Y-%m-%d %H:%M:%S.%3N')}] #{severity} -- #{progname}: #{msg}\n"
    end
    
    # Make it available globally
    Rails.application.config.ragdoll_logger = ragdoll_logger
  end
  
  # Configure Rails logger for more verbose output in development
  if Rails.env.development?
    config.log_level = :debug
    config.logger = ActiveSupport::Logger.new(STDOUT) if ENV['RAILS_LOG_TO_STDOUT'].present?
  end
end

# Custom logging methods for Ragdoll operations
module RagdollLogging
  def self.log_operation(operation, details = {})
    logger = Rails.application.config.ragdoll_logger || Rails.logger
    
    message = "🔧 RAGDOLL OPERATION: #{operation}"
    if details.any?
      message += " | DETAILS: #{details.to_json}"
    end
    
    logger.info(message)
    Rails.logger.info(message) if logger != Rails.logger
  end
  
  def self.log_error(operation, error, details = {})
    logger = Rails.application.config.ragdoll_logger || Rails.logger
    
    message = "💥 RAGDOLL ERROR: #{operation} failed"
    message += " | ERROR: #{error.class}: #{error.message}"
    message += " | DETAILS: #{details.to_json}" if details.any?
    message += " | BACKTRACE: #{error.backtrace.first(10).join(' | ')}"
    
    logger.error(message)
    Rails.logger.error(message) if logger != Rails.logger
  end
  
  def self.log_performance(operation, duration, details = {})
    logger = Rails.application.config.ragdoll_logger || Rails.logger
    
    message = "⏱️ RAGDOLL PERFORMANCE: #{operation} took #{duration.round(3)}s"
    if details.any?
      message += " | DETAILS: #{details.to_json}"
    end
    
    logger.info(message)
    Rails.logger.info(message) if logger != Rails.logger
  end
end