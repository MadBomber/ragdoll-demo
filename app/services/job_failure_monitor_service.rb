class JobFailureMonitorService
  STUCK_JOB_TIMEOUT = 5.minutes # If a job hasn't progressed in 5 minutes, consider it stuck
  PROGRESS_STATES_CACHE_KEY = 'ragdoll:job_progress_states'
  
  class << self
    # Track job progress states in Redis/memory
    def track_job_progress(session_id, file_id, filename, progress, status)
      progress_data = {
        session_id: session_id,
        file_id: file_id,
        filename: filename,
        progress: progress,
        status: status,
        last_updated: Time.current.to_i,
        stuck_detected: false
      }
      
      # Store individual job progress
      Rails.cache.write("job_progress:#{session_id}:#{file_id}", progress_data, expires_in: 1.hour)
      
      # Maintain an index of active jobs for efficient scanning
      active_jobs = Rails.cache.read('job_progress:active_jobs') || {}
      active_jobs["#{session_id}:#{file_id}"] = {
        session_id: session_id,
        file_id: file_id,
        filename: filename,
        last_updated: Time.current.to_i
      }
      Rails.cache.write('job_progress:active_jobs', active_jobs, expires_in: 1.hour)
      
      Rails.logger.info "📊 JobFailureMonitorService: Tracked progress for #{filename} - #{progress}% (#{status})"
    end
    
    # Check for stuck jobs and send failure updates
    def check_for_stuck_jobs
      Rails.logger.info "🔍 JobFailureMonitorService: Checking for stuck jobs..."
      
      stuck_jobs = find_stuck_jobs
      
      if stuck_jobs.any?
        Rails.logger.warn "⚠️ Found #{stuck_jobs.count} stuck jobs"
        stuck_jobs.each do |job_data|
          handle_stuck_job(job_data)
        end
      else
        Rails.logger.info "✅ No stuck jobs detected"
      end
      
      stuck_jobs.count
    end
    
    # Clean up completed or old job tracking data
    def cleanup_old_job_data
      Rails.logger.info "🧹 JobFailureMonitorService: Cleaning up old job data..."
      
      # This would need to be implemented based on cache backend
      # For Rails.cache, we'd need to maintain a separate index
      cleanup_count = 0
      
      Rails.logger.info "🧹 Cleaned up #{cleanup_count} old job records"
      cleanup_count
    end
    
    # Mark job as completed (remove from tracking)
    def mark_job_completed(session_id, file_id)
      Rails.cache.delete("job_progress:#{session_id}:#{file_id}")
      remove_from_active_jobs_index(session_id, file_id)
      Rails.logger.info "✅ JobFailureMonitorService: Marked job as completed: #{session_id}/#{file_id}"
    end
    
    # Mark job as failed (remove from tracking)
    def mark_job_failed(session_id, file_id)
      Rails.cache.delete("job_progress:#{session_id}:#{file_id}")
      remove_from_active_jobs_index(session_id, file_id)
      Rails.logger.info "❌ JobFailureMonitorService: Marked job as failed: #{session_id}/#{file_id}"
    end
    
    private
    
    def find_stuck_jobs
      stuck_jobs = []
      current_time = Time.current.to_i
      
      # Get active jobs index
      active_jobs = Rails.cache.read('job_progress:active_jobs') || {}
      
      active_jobs.each do |job_key, job_info|
        session_id = job_info[:session_id]
        file_id = job_info[:file_id]
        
        # Get detailed progress data
        progress_data = Rails.cache.read("job_progress:#{session_id}:#{file_id}")
        
        if progress_data
          time_since_update = current_time - progress_data[:last_updated]
          
          # Check if job is stuck (hasn't been updated in STUCK_JOB_TIMEOUT)
          if time_since_update > STUCK_JOB_TIMEOUT.to_i && !progress_data[:stuck_detected]
            Rails.logger.warn "⚠️ Found stuck job: #{progress_data[:filename]} (#{time_since_update}s since last update)"
            stuck_jobs << progress_data
          end
        else
          # Progress data missing but job still in active index - clean up
          Rails.logger.warn "🧹 Cleaning up orphaned job index entry: #{job_key}"
          active_jobs.delete(job_key)
        end
      end
      
      # Update the active jobs index if we cleaned up any orphaned entries
      if active_jobs.size != Rails.cache.read('job_progress:active_jobs')&.size
        Rails.cache.write('job_progress:active_jobs', active_jobs, expires_in: 1.hour)
      end
      
      stuck_jobs
    end
    
    def handle_stuck_job(job_data)
      session_id = job_data[:session_id]
      file_id = job_data[:file_id]
      filename = job_data[:filename]
      
      Rails.logger.error "💥 Detected stuck job: #{filename} (#{session_id}/#{file_id})"
      
      # Mark as stuck to avoid repeated notifications
      job_data[:stuck_detected] = true
      Rails.cache.write("job_progress:#{session_id}:#{file_id}", job_data, expires_in: 1.hour)
      
      # Send failure notification via ActionCable
      error_data = {
        file_id: file_id,
        filename: filename,
        status: 'error',
        progress: 0,
        message: 'Job appears to be stuck or crashed. Please try uploading again.'
      }
      
      begin
        ActionCable.server.broadcast("ragdoll_file_processing_#{session_id}", error_data)
        Rails.logger.info "📡 Sent stuck job notification to session #{session_id}"
      rescue => e
        Rails.logger.error "❌ Failed to broadcast stuck job notification: #{e.message}"
      end
      
      # Clean up the tracking data
      mark_job_failed(session_id, file_id)
    end
    
    def remove_from_active_jobs_index(session_id, file_id)
      active_jobs = Rails.cache.read('job_progress:active_jobs') || {}
      job_key = "#{session_id}:#{file_id}"
      
      if active_jobs.delete(job_key)
        Rails.cache.write('job_progress:active_jobs', active_jobs, expires_in: 1.hour)
        Rails.logger.debug "🧹 Removed job from active index: #{job_key}"
      end
    end
  end
end