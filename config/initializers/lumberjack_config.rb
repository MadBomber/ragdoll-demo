# frozen_string_literal: true

require 'lumberjack'

Rails.application.configure do
  if Rails.env.development? || Rails.env.test?
    # Logger is already configured in application.rb - just set up compatibility wrapper
    unified_logger = Rails.logger

    # Create a wrapper that adds Rails 8 broadcast_to compatibility
    class LumberjackRailsCompatibleLogger < SimpleDelegator
      def broadcast_to(logger)
        # Create a broadcast logger that sends to both lumberjack and the target logger
        Rails.logger = ActiveSupport::BroadcastLogger.new(__getobj__, logger)
      end
    end

    # Wrap the existing logger with Rails 8 compatibility
    Rails.logger = LumberjackRailsCompatibleLogger.new(unified_logger)

    # Also log to STDOUT in development if requested
    if ENV['RAILS_LOG_TO_STDOUT'].present?
      require 'lumberjack'
      stdout_logger = Lumberjack::Logger.new(
        STDOUT,
        level: :debug,
        datetime_format: '%Y-%m-%d %H:%M:%S.%3N',
        progname: 'App'
      )
      Rails.logger = LumberjackRailsCompatibleLogger.new(stdout_logger)
      Rails.application.config.logger = stdout_logger
    end

    # Use the same unified logger for Ragdoll (no separate log file)
    Rails.application.config.ragdoll_logger = unified_logger
  end
end

# Enhanced logging methods using Lumberjack features
module RagdollLumberjackLogging
  def self.logger
    @logger ||= Rails.application.config.ragdoll_logger || Rails.logger
  end

  def self.log_operation(operation, **details)
    # Use Lumberjack's structured logging with tags as metadata
    metadata = {
      operation: operation,
      type: 'operation',
      timestamp: Time.current.iso8601,
      **details
    }
    logger.info("🔧 RAGDOLL OPERATION: #{operation}", metadata)
  end

  def self.log_error(operation, error, **details)
    metadata = {
      operation: operation,
      type: 'error',
      error_class: error.class.name,
      error_message: error.message,
      backtrace: error.backtrace.first(10),
      timestamp: Time.current.iso8601,
      **details
    }
    logger.error("💥 RAGDOLL ERROR: #{operation} failed", metadata)
  end

  def self.log_performance(operation, duration, **details)
    metadata = {
      operation: operation,
      type: 'performance',
      duration: duration,
      duration_ms: (duration * 1000).round(2),
      timestamp: Time.current.iso8601,
      **details
    }
    logger.info("⏱️ RAGDOLL PERFORMANCE: #{operation} took #{duration.round(3)}s", metadata)
  end

  def self.log_job_status(job_class, job_id, status, **details)
    metadata = {
      job_class: job_class,
      job_id: job_id,
      type: 'job',
      status: status,
      timestamp: Time.current.iso8601,
      **details
    }

    case status
    when :started
      logger.info("🚀 JOB STARTED: #{job_class} [#{job_id}]", metadata)
    when :completed
      logger.info("✅ JOB COMPLETED: #{job_class} [#{job_id}]", metadata)
    when :failed
      logger.error("❌ JOB FAILED: #{job_class} [#{job_id}]", metadata)
    else
      logger.info("📊 JOB STATUS: #{job_class} [#{job_id}] - #{status}", metadata)
    end
  end

  def self.log_file_processing(filename, file_size, operation, **details)
    metadata = {
      filename: filename,
      file_size: file_size,
      file_size_human: format_file_size(file_size),
      type: 'file_processing',
      operation: operation,
      timestamp: Time.current.iso8601,
      **details
    }
    logger.info("📁 FILE PROCESSING: #{operation} for #{filename} (#{format_file_size(file_size)})", metadata)
  end

  def self.log_search(query, results_count, duration, **details)
    metadata = {
      query: query,
      results_count: results_count,
      type: 'search',
      duration: duration,
      duration_ms: (duration * 1000).round(2),
      timestamp: Time.current.iso8601,
      **details
    }
    logger.info("🔍 SEARCH: '#{query}' returned #{results_count} results in #{duration.round(3)}s", metadata)
  end

  def self.log_embedding(text_length, model, duration, **details)
    metadata = {
      text_length: text_length,
      model: model,
      type: 'embedding',
      duration: duration,
      duration_ms: (duration * 1000).round(2),
      chars_per_second: (text_length / duration).round(2),
      timestamp: Time.current.iso8601,
      **details
    }
    logger.info("🧮 EMBEDDING: Generated for #{text_length} chars using #{model} in #{duration.round(3)}s", metadata)
  end

  private

  def self.format_file_size(bytes)
    return '0 B' if bytes.zero?

    units = ['B', 'KB', 'MB', 'GB', 'TB']
    exp = (Math.log(bytes) / Math.log(1024)).to_i
    exp = [exp, units.length - 1].min

    "%.1f %s" % [bytes.to_f / (1024 ** exp), units[exp]]
  end
end

# Convenience methods for backward compatibility
module RagdollLogging
  def self.log_operation(operation, details = {})
    RagdollLumberjackLogging.log_operation(operation, **details)
  end

  def self.log_error(operation, error, details = {})
    RagdollLumberjackLogging.log_error(operation, error, **details)
  end

  def self.log_performance(operation, duration, details = {})
    RagdollLumberjackLogging.log_performance(operation, duration, **details)
  end
end