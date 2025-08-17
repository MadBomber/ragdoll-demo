class StuckJobMonitorJob < ApplicationJob
  queue_as :default
  
  # Run this job regularly to check for stuck file processing jobs
  def perform
    Rails.logger.info "🔍 StuckJobMonitorJob: Starting stuck job check"
    
    begin
      stuck_count = JobFailureMonitorService.check_for_stuck_jobs
      
      if stuck_count > 0
        Rails.logger.warn "⚠️ Found and handled #{stuck_count} stuck jobs"
      else
        Rails.logger.info "✅ No stuck jobs found"
      end
      
      # Clean up old job data periodically
      cleanup_count = JobFailureMonitorService.cleanup_old_job_data
      Rails.logger.info "🧹 Cleaned up #{cleanup_count} old job records" if cleanup_count > 0
      
    rescue => e
      Rails.logger.error "💥 StuckJobMonitorJob failed: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      
      # Don't re-raise - we want this job to keep running even if it fails occasionally
    end
  end
end