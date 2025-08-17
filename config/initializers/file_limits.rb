# frozen_string_literal: true

# Increase file descriptor limit for large directory uploads
# This helps prevent "too many open files" errors when processing many files
begin
  # Get current soft and hard limits
  soft_limit, hard_limit = Process.getrlimit(:NOFILE)
  
  # Set soft limit to hard limit (or a reasonable maximum)
  # This allows the process to open more files simultaneously
  new_limit = [hard_limit, 10240].min  # Don't exceed 10k file descriptors
  
  if soft_limit < new_limit
    Process.setrlimit(:NOFILE, new_limit, hard_limit)
    Rails.logger.info "File descriptor limit increased from #{soft_limit} to #{new_limit}"
  else
    Rails.logger.info "File descriptor limit already adequate: #{soft_limit}"
  end
rescue => e
  Rails.logger.warn "Could not adjust file descriptor limit: #{e.message}"
end