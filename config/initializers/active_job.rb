# frozen_string_literal: true

# Configure ActiveJob async adapter for concurrent processing
if Rails.application.config.active_job.queue_adapter == :async
  require 'concurrent/executor/thread_pool_executor'

  # Use JOB_CONCURRENT env var or default to 5 concurrent jobs
  max_threads = ENV.fetch('JOB_CONCURRENT', 5).to_i

  # Configure the async adapter with more threads for concurrent processing
  Rails.application.config.active_job.queue_adapter = ActiveJob::QueueAdapters::AsyncAdapter.new(
    min_threads: 1,
    max_threads: max_threads,  # Allow concurrent jobs based on env var
    max_queue: 100,            # Queue up to 100 jobs
    fallback_policy: :caller_runs
  )

  Rails.logger.info "ActiveJob async adapter configured with max_threads: #{max_threads}"
end