class WorkerMonitorJob < ApplicationJob
  queue_as :default
  
  # Run this job to monitor worker health - designed to be triggered manually or by cron
  def perform
    Rails.logger.info "🔍 WorkerMonitorJob: Checking worker health"
    
    health_status = WorkerHealthService.check_worker_health
    
    Rails.logger.info "📊 Worker Health Status: #{health_status}"
    
    if health_status[:needs_restart]
      Rails.logger.warn "⚠️ Workers need restart! Status: #{health_status[:status]}"
      
      # Process stuck jobs first
      if health_status[:stalled_jobs] > 0
        processed_count = WorkerHealthService.process_stuck_jobs!(5) # Process 5 at a time
        Rails.logger.info "🚀 Processed #{processed_count} stuck jobs before restart"
      end
      
      # Restart workers
      WorkerHealthService.restart_workers!
      
      Rails.logger.info "🔄 Worker restart completed"
    else
      Rails.logger.info "✅ Workers are healthy"
    end
  rescue => e
    Rails.logger.error "💥 WorkerMonitorJob failed: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    raise e # Re-raise to mark job as failed instead of scheduling retry
  end
end