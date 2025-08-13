class WorkerMonitorJob < ApplicationJob
  queue_as :default
  
  # Run this job every 2 minutes to monitor worker health
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
      
      # Schedule another check in 1 minute to verify restart worked
      WorkerMonitorJob.set(wait: 1.minute).perform_later
    else
      Rails.logger.info "✅ Workers are healthy"
      # Schedule next regular check
      WorkerMonitorJob.set(wait: 2.minutes).perform_later
    end
  rescue => e
    Rails.logger.error "💥 WorkerMonitorJob failed: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    
    # Schedule retry in 1 minute
    WorkerMonitorJob.set(wait: 1.minute).perform_later
  end
end