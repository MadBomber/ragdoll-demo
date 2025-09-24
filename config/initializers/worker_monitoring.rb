# Worker Monitoring Initializer
# DISABLED: Using async adapter instead of SolidQueue due to Ruby 3.4.6 + pg gem + ARM64 segmentation fault issues
# Starts automatic worker monitoring in development and production

# Rails.application.config.after_initialize do
#   # Only start monitoring if we're not in a Rails command context
#   # and SolidQueue is available
#   unless defined?(Rails::Console) || Rails.env.test? || $PROGRAM_NAME.include?('rake')
#     Rails.logger.info "🔍 Starting worker monitoring system..."
#
#     # Start the monitoring job after a short delay to let the app fully initialize
#     Thread.new do
#       sleep(10) # Wait 10 seconds for app to be ready
#       begin
#         WorkerMonitorJob.perform_later
#         Rails.logger.info "✅ Worker monitoring started"
#       rescue => e
#         Rails.logger.error "❌ Failed to start worker monitoring: #{e.message}"
#       end
#     end
#   end
# end

Rails.application.config.after_initialize do
  unless defined?(Rails::Console) || Rails.env.test? || $PROGRAM_NAME.include?('rake')
    Rails.logger.info "🔄 Using async job adapter - worker monitoring disabled"
  end
end