#!/usr/bin/env ruby

# Load Rails environment
require_relative './config/environment'

puts 'Starting job processor...'

loop do
  begin
    job = SolidQueue::Job.where(finished_at: nil).order(:created_at).first
    if job
      puts "Processing job ID: #{job.id}"
      
      # Extract the actual arguments from the nested structure
      actual_args = job.arguments.is_a?(Hash) ? job.arguments["arguments"] : job.arguments
      puts "Arguments: #{actual_args}"
      
      # Process the job manually
      ProcessFileJob.new.perform(*actual_args)
      
      # Mark as completed
      job.update!(finished_at: Time.current)
      puts "Completed job ID: #{job.id}"
    else
      puts 'No pending jobs, waiting...'
      sleep(2)
    end
  rescue => e
    puts "Error processing job: #{e.message}"
    puts e.backtrace.first(5)
    sleep(5)
  end
end