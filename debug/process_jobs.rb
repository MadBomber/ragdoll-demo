#!/usr/bin/env ruby

puts 'Processing all pending jobs manually...'
count = 0
SolidQueue::Job.where(finished_at: nil).find_each do |job|
  begin
    ProcessFileJob.perform_now(*job.arguments['arguments'])
    job.update!(finished_at: Time.current)
    count += 1
    puts "Processed job #{count}: #{job.arguments['arguments'][2]}"
  rescue => e
    puts "Failed to process job #{job.id}: #{e.message}"
  end
end
puts "Completed processing #{count} jobs"