#!/usr/bin/env ruby

# Script to fix document titles by re-extracting them from document content
# This applies our improved title extraction logic to existing documents

puts "🔧 Starting document title fix process..."

# Counter for tracking progress
fixed_count = 0
total_count = 0

# Process documents in batches to avoid memory issues
batch_size = 50

# Get the total count first
total_documents = Ragdoll::Document.count
puts "📊 Found #{total_documents} documents to process"

# Process documents in batches
Ragdoll::Document.find_each(batch_size: batch_size) do |document|
  total_count += 1
  
  begin
    original_title = document.title
    
    # Skip if title doesn't look like a hash-based name (including spaced version)
    unless original_title.match?(/^[a-fA-F0-9]{32}[_ ]\d+[_ ]\d+[_ ]/)
      puts "⏭️  Skipping document #{document.id}: '#{original_title}' (already has proper title)"
      next
    end
    
    # Try to extract a better title from the document
    new_title = nil
    
    # Method 1: Read content from the document file location
    if document.location.present? && File.exist?(document.location)
      content = File.read(document.location)
      
      # Try YAML front matter extraction
      if content.start_with?("---\n")
        lines = content.lines
        closing_index = nil
        
        lines.each_with_index do |line, index|
          next if index == 0
          if line.strip == "---"
            closing_index = index
            break
          end
        end
        
        if closing_index
          yaml_lines = lines[1...closing_index]
          yaml_content = yaml_lines.join
          
          begin
            require 'yaml'
            front_matter = YAML.safe_load(yaml_content, permitted_classes: [Time, Date])
            if front_matter.is_a?(Hash) && front_matter['title']
              new_title = front_matter['title'].to_s.strip
            end
          rescue YAML::SyntaxError => e
            puts "⚠️  YAML parsing failed for document #{document.id}: #{e.message}"
          end
        end
      end
      
      # Method 2: Try to extract markdown heading (# or ##)
      if new_title.blank?
        # Look for markdown headings (# or ##)
        heading_match = content.match(/^#+\s+(.+)$/m)
        if heading_match
          heading_content = heading_match[1].strip
          new_title = heading_content unless heading_content.empty?
        end
      end
      
      # Method 3: Try to extract H1 tag from HTML content
      if new_title.blank? && content.include?('<h1')
        h1_match = content.match(/<h1[^>]*>(.*?)<\/h1>/mi)
        if h1_match
          h1_content = h1_match[1]
          # Remove nested HTML tags
          h1_content = h1_content.gsub(/<[^>]+>/, '').strip
          new_title = h1_content unless h1_content.empty?
        end
      end
    end
    
    # Method 4: Extract title from filepath (fallback)
    if new_title.blank? && document.title.present?
      # Try to extract from the hash-based name (both underscore and space versions)
      if document.title.match(/^[a-fA-F0-9]{32}[_ ]\d+[_ ]\d+[_ ](.+)$/)
        filename_part = $1
        # Clean up the filename
        clean_title = filename_part
          .gsub(/\.(md|html|txt|pdf|docx)$/, '') # Remove file extensions
          .gsub(/[-_]/, ' ')                      # Replace hyphens and underscores with spaces
          .gsub(/([a-z])([A-Z])/, '\1 \2')       # Handle camelCase
          .split(' ')
          .map(&:capitalize)
          .join(' ')
          .strip
        
        new_title = clean_title unless clean_title.empty?
      end
    end
    
    # Update the document if we found a better title
    if new_title.present? && new_title != original_title
      document.update!(title: new_title)
      fixed_count += 1
      puts "✅ Fixed document #{document.id}: '#{original_title}' → '#{new_title}'"
    else
      puts "❌ No better title found for document #{document.id}: '#{original_title}'"
    end
    
  rescue => e
    puts "💥 Error processing document #{document.id}: #{e.message}"
    puts e.backtrace.first(3)
  end
  
  # Progress indicator
  if total_count % 10 == 0
    puts "📈 Progress: #{total_count}/#{total_documents} (#{fixed_count} fixed so far)"
  end
end

puts ""
puts "🎉 Document title fix completed!"
puts "📊 Results:"
puts "   Total documents processed: #{total_count}"
puts "   Documents with titles fixed: #{fixed_count}"
puts "   Documents unchanged: #{total_count - fixed_count}"
puts ""

if fixed_count > 0
  puts "🔄 Sample of fixed titles:"
  Ragdoll::Document.limit(5).each do |doc|
    puts "   ID #{doc.id}: #{doc.title}"
  end
end