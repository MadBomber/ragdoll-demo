#!/usr/bin/env ruby
# Script to manually trigger worker health monitoring
# Usage: ruby scripts/monitor_workers.rb

require_relative '../config/environment'

puts "🔍 Manual Worker Health Check"
puts "=" * 40

begin
  # Trigger worker monitoring job
  WorkerMonitorJob.perform_now
  puts "✅ Worker monitoring completed successfully"
rescue => e
  puts "❌ Worker monitoring failed: #{e.message}"
  puts e.backtrace.first(5).join("\n")
  exit 1
end