namespace :cleanup do
  desc "Clean up orphaned temporary upload files"
  task temp_files: :environment do
    uploads_dir = Rails.root.join('tmp', 'uploads')
    
    unless Dir.exist?(uploads_dir)
      puts "Upload directory does not exist: #{uploads_dir}"
      next
    end
    
    # Find files older than 1 hour (assuming processing should complete within 1 hour)
    cutoff_time = 1.hour.ago
    cleaned_count = 0
    total_size = 0
    
    Dir.glob(File.join(uploads_dir, '**', '*')).each do |file_path|
      next unless File.file?(file_path)
      next if file_path.include?('cache') # Skip cache directory
      
      file_mtime = File.mtime(file_path)
      file_size = File.size(file_path)
      
      if file_mtime < cutoff_time
        puts "Cleaning up orphaned file: #{file_path} (#{file_size} bytes, #{time_ago_in_words(file_mtime)} old)"
        File.delete(file_path)
        cleaned_count += 1
        total_size += file_size
      end
    end
    
    if cleaned_count > 0
      puts "✅ Cleaned up #{cleaned_count} orphaned files (#{number_to_human_size(total_size)} total)"
    else
      puts "✅ No orphaned files found"
    end
  end
  
  desc "Clean up all temporary upload files (force cleanup)"
  task force_temp_files: :environment do
    uploads_dir = Rails.root.join('tmp', 'uploads')
    
    unless Dir.exist?(uploads_dir)
      puts "Upload directory does not exist: #{uploads_dir}"
      next
    end
    
    cleaned_count = 0
    total_size = 0
    
    Dir.glob(File.join(uploads_dir, '**', '*')).each do |file_path|
      next unless File.file?(file_path)
      next if file_path.include?('cache') # Skip cache directory
      
      file_size = File.size(file_path)
      
      puts "Force cleaning: #{file_path} (#{file_size} bytes)"
      File.delete(file_path)
      cleaned_count += 1
      total_size += file_size
    end
    
    if cleaned_count > 0
      puts "✅ Force cleaned #{cleaned_count} files (#{number_to_human_size(total_size)} total)"
    else
      puts "✅ No files found to clean"
    end
  end
  
  private
  
  def time_ago_in_words(time)
    seconds = Time.current - time
    case seconds
    when 0...60
      "#{seconds.to_i} seconds"
    when 60...3600
      "#{(seconds / 60).to_i} minutes"
    when 3600...86400
      "#{(seconds / 3600).to_i} hours"
    else
      "#{(seconds / 86400).to_i} days"
    end
  end
  
  def number_to_human_size(size)
    units = ['B', 'KB', 'MB', 'GB', 'TB']
    unit_index = 0
    
    while size >= 1024 && unit_index < units.length - 1
      size /= 1024.0
      unit_index += 1
    end
    
    "#{size.round(1)} #{units[unit_index]}"
  end
end