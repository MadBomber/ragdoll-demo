class WorkerHealthService
  WORKER_TIMEOUT = 5.minutes
  STALLED_JOB_TIMEOUT = 10.minutes
  
  class << self
    def check_worker_health
      {
        workers_running: workers_running?,
        worker_count: worker_count,
        stalled_jobs: stalled_jobs_count,
        oldest_pending_job: oldest_pending_job_age,
        needs_restart: needs_restart?,
        status: overall_status
      }
    end
    
    def needs_restart?
      # Restart if:
      # 1. No workers are running
      # 2. Jobs are pending for more than STALLED_JOB_TIMEOUT and workers exist
      # 3. Workers are running but no jobs processed in last WORKER_TIMEOUT
      !workers_running? || 
      (stalled_jobs_count > 0 && oldest_pending_job_age > STALLED_JOB_TIMEOUT) ||
      workers_appear_stuck?
    end
    
    def restart_workers!
      Rails.logger.info "🔄 WorkerHealthService: Restarting stalled workers"
      
      # Kill existing workers
      kill_workers
      
      # Wait a moment for processes to die
      sleep(2)
      
      # Workers should restart automatically via Foreman
      # But we can also manually start them if needed
      unless Rails.env.production?
        restart_workers_manually
      end
      
      Rails.logger.info "✅ WorkerHealthService: Worker restart completed"
    end
    
    def process_stuck_jobs!(limit = 10)
      Rails.logger.info "🚀 WorkerHealthService: Processing stuck jobs manually"
      
      count = 0
      SolidQueue::Job.where(finished_at: nil)
                     .where('created_at < ?', STALLED_JOB_TIMEOUT.ago)
                     .limit(limit)
                     .find_each do |job|
        begin
          case job.class_name
          when 'ProcessFileJob'
            ProcessFileJob.perform_now(*job.arguments['arguments'])
            job.update!(finished_at: Time.current)
            count += 1
            Rails.logger.info "✅ Processed stuck job: #{job.arguments['arguments'][2]}"
          else
            # Handle other job types as needed
            Rails.logger.warn "⚠️ Unknown job type: #{job.class_name}"
          end
        rescue => e
          Rails.logger.error "💥 Failed to process job #{job.id}: #{e.message}"
        end
      end
      
      Rails.logger.info "🎉 WorkerHealthService: Processed #{count} stuck jobs"
      count
    end
    
    private
    
    def workers_running?
      worker_count > 0
    end
    
    def worker_count
      `ps aux | grep -E "solid-queue-worker" | grep -v grep | wc -l`.strip.to_i
    end
    
    def stalled_jobs_count
      SolidQueue::Job.where(finished_at: nil)
                     .where('scheduled_at <= ?', Time.current)
                     .count
    end
    
    def oldest_pending_job_age
      oldest_job = SolidQueue::Job.where(finished_at: nil)
                                  .where('scheduled_at <= ?', Time.current)
                                  .order(:created_at)
                                  .first
      return 0 unless oldest_job
      
      Time.current - oldest_job.created_at
    end
    
    def workers_appear_stuck?
      # Check if workers exist but haven't processed jobs recently
      return false unless workers_running?
      
      recent_completions = SolidQueue::Job.where('finished_at > ?', WORKER_TIMEOUT.ago).count
      pending_jobs = stalled_jobs_count
      
      # If we have pending jobs but no recent completions, workers might be stuck
      pending_jobs > 0 && recent_completions == 0
    end
    
    def overall_status
      if !workers_running?
        'no_workers'
      elsif stalled_jobs_count == 0
        'healthy'
      elsif oldest_pending_job_age > STALLED_JOB_TIMEOUT
        'stalled'
      else
        'processing'
      end
    end
    
    def kill_workers
      system('pkill -f "solid-queue-worker"')
    end
    
    def restart_workers_manually
      # This will be handled by Foreman in development
      # In production, you might need a different approach
      if Rails.env.development?
        Rails.logger.info "Workers will restart automatically via Foreman"
      end
    end
  end
end