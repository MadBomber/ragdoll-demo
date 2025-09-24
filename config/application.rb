require_relative "boot"

require "rails"
# Pick the frameworks you want:
require "active_model/railtie"
require "active_job/railtie"
require "active_record/railtie"
require "active_storage/engine"
require "action_controller/railtie"
require "action_mailer/railtie"
require "action_mailbox/engine"
require "action_text/engine"
require "action_view/railtie"
require "action_cable/engine"
# require "rails/test_unit/railtie"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

require "ragdoll/rails"

module Dummy
  class Application < Rails::Application
    # Supports ngrok
    config.hosts << "a2428ae3e113.ngrok-free.app"
    config.hosts << "a2428ae3e113.ngrok-free.app"

    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 8.0

    # Configure lumberjack logger at application level to prevent development.log creation
    if Rails.env.development? || Rails.env.test?
      require 'lumberjack'
      log_file = Rails.root.join('log', 'lumberjack.log')

      # Create unified lumberjack logger
      unified_logger = Lumberjack::Logger.new(
        log_file,
        level: :debug,
        datetime_format: '%Y-%m-%d %H:%M:%S.%3N',
        max_size: 50.megabytes,
        keep_files: 5,
        progname: 'App',
        tags: {
          pid: Process.pid,
          host: Socket.gethostname
        }
      )

      # Override Rails default logger before it creates development.log
      config.logger = unified_logger
      config.log_level = :debug
    end

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[assets tasks])

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")

    # Don't generate system test files.
    config.generators.system_tests = nil

    # Increase multipart file limit for large directory uploads
    config.force_ssl = false if Rails.env.development?
  end
end
