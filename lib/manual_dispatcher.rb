#!/usr/bin/env ruby
# Manual dispatcher to work around SolidQueue dispatcher issues

class ManualDispatcher
  def self.dispatch_ready_jobs(limit = 10)
    dispatched = 0
    
    # Find jobs ready for dispatch (excluding DispatcherJob to avoid recursion)
    ready_jobs = SolidQueue::Job
      .where('scheduled_at <= ?', Time.current)
      .where.not(class_name: 'DispatcherJob')
      .limit(limit)
      
    ready_jobs.each do |job|
      begin
        # Check if ready execution already exists for this job
        unless SolidQueue::ReadyExecution.exists?(job_id: job.id)
          ready_execution = SolidQueue::ReadyExecution.create!(
            job_id: job.id,
            queue_name: job.queue_name,
            priority: job.priority
          )
          dispatched += 1
          puts "✅ Dispatched job #{job.id} (#{job.class_name}) - ready execution #{ready_execution.id}"
        end
      rescue => e
        puts "❌ Failed to dispatch job #{job.id}: #{e.message}"
      end
    end
    
    puts "📦 Dispatched #{dispatched} jobs"
    dispatched
  end
  
  def self.run_continuous_dispatch(interval = 5)
    puts "🔄 Starting continuous manual dispatcher (interval: #{interval}s)"
    puts "Press Ctrl+C to stop"
    
    loop do
      dispatch_ready_jobs
      sleep interval
    end
  rescue Interrupt
    puts "\n👋 Manual dispatcher stopped"
  end
end

# Run if called directly
if __FILE__ == $0
  ManualDispatcher.run_continuous_dispatch
end