class DispatcherJob < ApplicationJob
  queue_as :default

  def perform
    require Rails.root.join('lib/manual_dispatcher.rb')
    
    # Check if this is a DispatcherJob to avoid infinite recursion
    non_dispatcher_jobs = SolidQueue::Job
      .where('scheduled_at <= ?', Time.current)
      .where.not(class_name: 'DispatcherJob')
      .count
    
    # Only dispatch if there are actual jobs to process (not just DispatcherJobs)
    if non_dispatcher_jobs > 0
      # Dispatch ready jobs, limit to avoid overwhelming the system
      dispatched = ManualDispatcher.dispatch_ready_jobs(25)
      
      if dispatched > 0
        Rails.logger.info "🚀 DispatcherJob: Dispatched #{dispatched} jobs"
      end
      
      # Schedule the next run in 30 seconds (longer interval to avoid spam)
      # Only if there are still non-dispatcher jobs remaining
      remaining_jobs = SolidQueue::Job
        .where('scheduled_at <= ?', Time.current)
        .where.not(class_name: 'DispatcherJob')
        .count
        
      if remaining_jobs > 0
        DispatcherJob.set(wait: 30.seconds).perform_later
        Rails.logger.info "📋 DispatcherJob: #{remaining_jobs} jobs remaining, scheduling next run in 30s"
      else
        Rails.logger.info "✅ DispatcherJob: All jobs dispatched, stopping automatic dispatch"
      end
    else
      Rails.logger.info "ℹ️ DispatcherJob: No jobs to dispatch (#{non_dispatcher_jobs} remaining)"
    end
  end
end