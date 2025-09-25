# frozen_string_literal: true

# Configure ActiveJob with a custom concurrent adapter
require 'active_job'
require 'concurrent'

# Custom queue adapter that maintains a persistent thread pool
class ConcurrentAdapter
  def enqueue(job)
    enqueue_at(job, nil)
  end

  def enqueue_at(job, timestamp)
    if timestamp && timestamp > Time.current
      # Handle delayed jobs (not needed for our use case, but required by interface)
      delay = timestamp - Time.current
      executor.post do
        sleep(delay)
        job.perform_now
      end
    else
      # Execute immediately in thread pool
      executor.post do
        job.perform_now
      end
    end
  end

  private

  def executor
    @executor ||= begin
      base_threads = ENV.fetch('JOB_CONCURRENT', 5).to_i
      # Account for additional background jobs that each file upload triggers:
      # ProcessFileJob + GenerateEmbeddingsJob + GenerateSummaryJob + ExtractKeywordsJob
      # So each file needs 4 threads. Multiply by 1.5x for safety margin.
      max_threads = (base_threads * 4 * 1.5).to_i

      Rails.logger.info "🧵 ConcurrentAdapter: Setting up thread pool with #{max_threads} threads (base: #{base_threads})"

      Concurrent::ThreadPoolExecutor.new(
        min_threads: [max_threads / 4, 2].max, # Keep some threads always available
        max_threads: max_threads,
        max_queue: 1000,
        fallback_policy: :caller_runs,
        auto_terminate: false,
        # Add thread naming for debugging
        idletime: 60 # Allow threads to expire after 60s idle
      )
    end
  end
end

# Set our custom adapter
Rails.application.config.active_job.queue_adapter = ConcurrentAdapter.new

Rails.logger.info "ActiveJob configured with custom concurrent adapter (max_threads: #{ENV.fetch('JOB_CONCURRENT', 5)})"