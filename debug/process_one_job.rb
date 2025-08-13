#!/usr/bin/env ruby

# Process one job manually to test the system
job = SolidQueue::Job.where(finished_at: nil).first
if job
  puts "Processing job ID: #{job.id}, Class: #{job.class_name}"
  puts "Arguments: #{job.arguments}"
  
  # Process the job manually
  # Extract the actual arguments from the nested structure
  actual_args = job.arguments.is_a?(Hash) ? job.arguments["arguments"] : job.arguments
  puts "Actual arguments: #{actual_args}"
  ProcessFileJob.new.perform(*actual_args)
  
  # Mark as completed
  job.update!(finished_at: Time.current)
  puts 'Job completed successfully'
else
  puts 'No pending jobs found'
end